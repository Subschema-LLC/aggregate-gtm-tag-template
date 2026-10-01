import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

// This runs the exported scenarios as ordinary JavaScript with small API mocks.
// It does not implement GTM's sandbox, permission enforcement, or browser runtime.
const source = readFileSync(new URL('../template.tpl', import.meta.url), 'utf8');
const sections = new Map();
const markers = [...source.matchAll(/^___([A-Z_]+)___\s*$/gm)];
for (let index = 0; index < markers.length; index++) {
  const marker = markers[index];
  assert.ok(!sections.has(marker[1]), `Duplicate section: ${marker[1]}`);
  sections.set(marker[1], source.slice(
    marker.index + marker[0].length,
    markers[index + 1]?.index ?? source.length,
  ).trim());
}

const info = JSON.parse(sections.get('INFO'));
const parameters = JSON.parse(sections.get('TEMPLATE_PARAMETERS'));
const permissions = JSON.parse(sections.get('WEB_PERMISSIONS'));
const template = new vm.Script(
  `(function(data) {\n${sections.get('SANDBOXED_JS_FOR_WEB_TEMPLATE')}\n})(data);`,
  { filename: 'template.tpl:SANDBOXED_JS_FOR_WEB_TEMPLATE' },
);

// Only the simple block-scalar format emitted by this template is supported;
// reject other YAML constructs instead of silently skipping scenarios.
function readScenarios(text) {
  const lines = text.split('\n');
  assert.equal(lines.shift(), 'scenarios:');
  const scenarios = [];
  while (lines.length) {
    if (!lines[0].trim()) {
      lines.shift();
      continue;
    }
    const match = /^- name: (.+)$/.exec(lines.shift());
    assert.ok(match, 'Expected a scenario name');
    assert.equal(lines.shift(), '  code: |-');
    const code = [];
    while (lines.length && !lines[0].startsWith('- name: ')) {
      const line = lines.shift();
      assert.ok(!line.trim() || line.startsWith('    '), 'Invalid scenario indentation');
      code.push(line.slice(4));
    }
    scenarios.push({ name: match[1], code: code.join('\n') });
  }
  assert.ok(scenarios.length, 'The template must include executable scenarios');
  assert.equal(new Set(scenarios.map(({ name }) => name)).size, scenarios.length);
  return scenarios;
}

// Remove VM realm-specific prototypes while preserving values such as undefined.
function comparable(value) {
  if (Array.isArray(value)) return Array.from(value, comparable);
  if (value !== null && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, comparable(item)]));
  }
  return value;
}

function parseUrl(value) {
  try {
    const url = new URL(value);
    return {
      href: url.href,
      origin: url.origin,
      protocol: url.protocol,
      username: url.username,
      password: url.password,
      host: url.host,
      hostname: url.hostname,
      port: url.port,
      pathname: url.pathname,
      search: url.search,
      searchParams: Object.fromEntries(Array.from(url.searchParams.keys(), key => {
        const values = url.searchParams.getAll(key);
        return [key, values.length === 1 ? values[0] : values];
      })),
      hash: url.hash,
    };
  } catch {
    return undefined;
  }
}

function runScenario({ name, code }) {
  const mocks = new Map();
  const calls = new Map();
  let runs = 0;
  const defaults = {
    getType: value => value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value,
    parseUrl,
    encodeUriComponent(value) {
      try {
        return encodeURIComponent(value);
      } catch (error) {
        if (error instanceof URIError) return undefined;
        throw error;
      }
    },
    queryPermission(permission, ...args) {
      if (permission === 'access_globals') {
        const accessType = args[0];
        const key = args[1];
        const ag = permissions.find(p => p.instance.key.publicId === 'access_globals');
        const keys = ag ? permissionValue(ag.instance.param.find(p => p.key === 'keys').value) : [];
        const entry = keys.find(k => k.key === key);
        return entry ? Boolean(entry[accessType]) : false;
      }
      assert.ok(['inject_script', 'logging'].includes(permission), `Unknown permission: ${permission}`);
      // Scenarios must explicitly grant permissions instead of depending on
      // the installation hostname configured in the template editor.
      return false;
    },
    injectScript: () => assert.fail('Mock injectScript and invoke its success or failure callback'),
    copyFromWindow: () => undefined,
    callInWindow: () => undefined,
    logToConsole: () => undefined,
    // GTM exposes Object as a namespace of functions rather than a function.
    Object: { keys: value => Object.keys(value) },
  };

  function record(apiName, args) {
    if (!calls.has(apiName)) calls.set(apiName, []);
    calls.get(apiName).push(args);
  }

  vm.runInNewContext(code, {
    mock(apiName, implementation) {
      assert.equal(typeof implementation, 'function', `Invalid mock for ${apiName}`);
      mocks.set(apiName, implementation);
    },
    runCode(input) {
      const previousCompletions = (calls.get('gtmOnSuccess')?.length ?? 0)
        + (calls.get('gtmOnFailure')?.length ?? 0);
      runs++;
      template.runInNewContext({
        data: {
          ...input,
          gtmOnSuccess: (...args) => record('gtmOnSuccess', args),
          gtmOnFailure: (...args) => record('gtmOnFailure', args),
        },
        require(apiName) {
          const implementation = mocks.get(apiName) ?? defaults[apiName];
          if (implementation !== null && typeof implementation === 'object') {
            return Object.fromEntries(Object.entries(implementation).map(([name, method]) => {
              assert.equal(typeof method, 'function', `Unsupported GTM API: ${apiName}.${name}`);
              return [name, (...args) => {
                record(`${apiName}.${name}`, args);
                return method(...args);
              }];
            }));
          }
          assert.equal(typeof implementation, 'function', `Unsupported GTM API: ${apiName}`);
          return (...args) => {
            record(apiName, args);
            return implementation(...args);
          };
        },
      }, { timeout: 1000 });
      const completions = (calls.get('gtmOnSuccess')?.length ?? 0)
        + (calls.get('gtmOnFailure')?.length ?? 0);
      assert.equal(completions - previousCompletions, 1,
        'Each synchronous run must signal exactly one completion');
    },
    assertThat(actual) {
      return {
        isEqualTo(expected) {
          assert.deepEqual(comparable(actual), comparable(expected));
        },
      };
    },
    assertApi(apiName) {
      return {
        wasCalled() {
          assert.ok(calls.get(apiName)?.length, `${apiName} was not called`);
        },
        wasNotCalled() {
          assert.equal(calls.get(apiName)?.length ?? 0, 0, `${apiName} was called`);
        },
        wasCalledWith(...expected) {
          assert.ok((calls.get(apiName) ?? []).some(args => {
            try {
              assert.deepEqual(comparable(args), comparable(expected));
              return true;
            } catch {
              return false;
            }
          }), `${apiName} was not called with the expected arguments`);
        },
      };
    },
  }, { filename: `template.tpl:TESTS:${name}`, timeout: 1000 });
  assert.ok(runs, 'Each scenario must execute the template');
}

test('template metadata and editor parameters contain valid JSON for a web tag', () => {
  assert.equal(info.type, 'TAG');
  assert.deepEqual(info.containerContexts, ['WEB']);
  assert.equal(info.displayName, 'Aggregate');
  assert.ok(Array.isArray(info.categories) && info.categories.length >= 1 && info.categories.length <= 3);
  assert.equal(info.brand.displayName, 'Subschema LLC');
  assert.match(info.brand.thumbnail, new RegExp("^data:image/(?:png|jpeg|gif);base64,[A-Za-z0-9+/=]+$"));
  assert.ok(info.brand.thumbnail.length < 50 * 1024 * 1.37, 'Thumbnail must be under 50kB');
  assert.ok(Array.isArray(parameters));
  assert.ok(Array.isArray(permissions));
  const names = parameters.map(parameter => parameter.name);
  assert.equal(new Set(names).size, names.length, 'Duplicate parameter names');
});

test('editor defaults to initialization and enables fields for the selected action', () => {
  const byName = Object.fromEntries(parameters.map(parameter => [parameter.name, parameter]));
  assert.equal(byName.action.defaultValue, 'initialize');
  assert.deepEqual(byName.action.selectItems.map(({ value }) => value), ['initialize', 'event']);
  for (const [action, names] of Object.entries({
    initialize: ['scriptUrl', 'endpoint', 'websiteToken'],
    event: ['eventName', 'customData', 'eventProperties', 'goalEvent'],
  })) {
    for (const name of names) {
      assert.deepEqual(byName[name].enablingConditions, [
        { paramName: 'action', paramValue: action, type: 'EQUALS' },
      ], `${name} must be enabled only for the ${action} action`);
    }
  }
  assert.equal(byName.action.enablingConditions, undefined);
  assert.equal(byName.objectName.enablingConditions, undefined);
  assert.equal(byName.objectName.defaultValue, 'Aggregate');
  assert.equal(byName.log.enablingConditions, undefined);
});

function permissionValue(value) {
  if (value.type === 1) return value.string;
  if (value.type === 2) return value.listItem.map(permissionValue);
  if (value.type === 3) {
    return Object.fromEntries(value.mapKey.map((key, index) => [
      permissionValue(key), permissionValue(value.mapValue[index]),
    ]));
  }
  if (value.type === 8) return value.boolean;
  assert.fail(`Unsupported permission value type: ${value.type}`);
}

test('permissions allow HTTPS loading, Aggregate.emit access, and debug logging', () => {
  const settings = Object.fromEntries(permissions.map(({ instance }) => [
    instance.key.publicId,
    Object.fromEntries(instance.param.map(({ key, value }) => [key, permissionValue(value)])),
  ]));
  assert.deepEqual(Object.keys(settings).sort(), ['access_globals', 'inject_script', 'logging']);
  assert.ok(settings.inject_script.urls.length);
  for (const pattern of settings.inject_script.urls) {
    // Use a concrete deployment host and an explicit path; a bare wildcard host
    // is rejected by GTM even though it looks like a general URL glob.
    assert.match(pattern, /^https:\/\/[A-Za-z0-9.-]+(?::[0-9]+)?\/[^\s]*$/,
      `Script permission must specify an HTTPS hostname and path: ${pattern}`);
  }
  assert.deepEqual(settings.access_globals.keys, [
    { key: 'Aggregate.emit', read: true, write: false, execute: true },
  ]);
  assert.equal(settings.logging.environments, 'debug');
});

test('editor validators accept supported script URLs and event names', () => {
  function patternFor(name) {
    const parameter = parameters.find(parameter => parameter.name === name);
    assert.ok(parameter, `Missing editor parameter: ${name}`);
    const validator = parameter.valueValidators.find(validator => validator.type === 'REGEX');
    assert.ok(validator, `Missing regex validator: ${name}`);
    return new RegExp(validator.args[0]);
  }

  const scriptUrl = patternFor('scriptUrl');
  for (const value of [
    'https://analytics.example.com/aggregate.js',
    'https://analytics.example.com/aggregate.js?min=1',
    'https://analytics.example.com/metrics/aggregate.js',
  ]) {
    assert.ok(scriptUrl.test(value), `Supported script URL rejected: ${value}`);
  }
  for (const value of [
    '',
    'http://analytics.example.com/aggregate.js',
    'https://analytics.example.com/other.js',
    'https://analytics.example.com/aggregate.js?token=inline',
    'https://analytics.example.com/aggregate.js?min=0',
    'https://analytics.example.com/aggregate.js#fragment',
  ]) {
    assert.ok(!scriptUrl.test(value), `Unsupported script URL accepted: ${value}`);
  }

  const eventName = patternFor('eventName');
  for (const value of ['signup_click', 'Checkout.Step-1:complete', 'a'.repeat(100)]) {
    assert.ok(eventName.test(value), `Supported event name rejected: ${value}`);
  }
  for (const value of ['', 'Signup Completed', '1signup', 'signup/path', 'a'.repeat(101)]) {
    assert.ok(!eventName.test(value), `Unsupported event name accepted: ${value}`);
  }

  const objectName = patternFor('objectName');
  for (const value of ['Aggregate', 'CompanyAnalytics', 'my_tracker', 'Tracker123']) {
    assert.ok(objectName.test(value), `Supported object name rejected: ${value}`);
  }
  for (const value of ['', '_private', '1tracker', 'two words', 'tracker-dash', 'tracker/slash']) {
    assert.ok(!objectName.test(value), `Unsupported object name accepted: ${value}`);
  }

  const goalEvent = patternFor('goalEvent');
  for (const value of ['signup', 'purchase_completed', 'checkout.step-1:done']) {
    assert.ok(goalEvent.test(value), `Supported goal code rejected: ${value}`);
  }
  for (const value of ['', '1signup', 'two words', 'signup/slash']) {
    assert.ok(!goalEvent.test(value), `Unsupported goal code accepted: ${value}`);
  }
});

const scenarios = readScenarios(sections.get('TESTS'));

test('exported scenario names use only letters numbers and spaces', () => {
  // Keep names in a conservative subset accepted by GTM; dots prevent import.
  for (const { name } of scenarios) {
    assert.match(name, /^[A-Za-z0-9 ]+$/, `Unsupported character in GTM test name: ${name}`);
  }
});

for (const scenario of scenarios) {
  test(scenario.name, () => runScenario(scenario));
}
