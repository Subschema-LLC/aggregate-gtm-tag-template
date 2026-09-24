___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Aggregate",
  "categories": [
    "ANALYTICS"
  ],
  "brand": {
    "id": "github.com_subschema-llc",
    "displayName": "Subschema LLC",
    "thumbnail": ""
  },
  "description": "Initializes the Aggregate browser SDK or sends a custom event with optional properties.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "SELECT",
    "name": "action",
    "displayName": "Tag action",
    "simpleValueType": true,
    "defaultValue": "initialize",
    "selectItems": [
      {
        "value": "initialize",
        "displayValue": "Initialize SDK (automatic page view)"
      },
      {
        "value": "event",
        "displayValue": "Send event"
      }
    ],
    "alwaysInSummary": true
  },
  {
    "type": "TEXT",
    "name": "scriptUrl",
    "displayName": "Aggregate script URL",
    "simpleValueType": true,
    "help": "Your installation's HTTPS /aggregate.js URL, optionally with ?min=1. Set your host under template Permissions > Injects scripts before saving. Use the configured server route and the default Aggregate namespace.",
    "enablingConditions": [
      {"paramName": "action", "paramValue": "initialize", "type": "EQUALS"}
    ],
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      },
      {
        "type": "REGEX",
        "args": [
          "^https://[^\\s/?#@\\\\]+(/[^\\s?#@\\\\]*)?/aggregate\\.js(\\?min=1)?$"
        ]
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "endpoint",
    "displayName": "Collector endpoint",
    "simpleValueType": true,
    "help": "Absolute HTTPS collector URL, for example https://analytics.example.com/api/receive.",
    "enablingConditions": [
      {"paramName": "action", "paramValue": "initialize", "type": "EQUALS"}
    ],
    "valueValidators": [
      {"type": "NON_EMPTY"},
      {"type": "REGEX", "args": ["^https://[^\\s/?#@\\\\]+([/?][^\\s#\\\\]*)?$"]}
    ]
  },
  {
    "type": "TEXT",
    "name": "websiteToken",
    "displayName": "Public website token",
    "simpleValueType": true,
    "help": "Public tracking token from your registered website, not an organization sharing token.",
    "enablingConditions": [
      {"paramName": "action", "paramValue": "initialize", "type": "EQUALS"}
    ],
    "valueValidators": [{"type": "NON_EMPTY"}]
  },
  {
    "type": "TEXT",
    "name": "eventName",
    "displayName": "Event name",
    "simpleValueType": true,
    "help": "Fixed event name passed to Aggregate.emit(), for example signup_completed. Initialize the SDK before this tag fires.",
    "enablingConditions": [
      {"paramName": "action", "paramValue": "event", "type": "EQUALS"}
    ],
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      },
      {
        "type": "REGEX",
        "args": ["^[A-Za-z][A-Za-z0-9_.:-]{0,99}$"]
      }
    ]
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "eventProperties",
    "displayName": "Event properties",
    "enablingConditions": [
      {"paramName": "action", "paramValue": "event", "type": "EQUALS"}
    ],
    "simpleTableColumns": [
      {
        "name": "name",
        "displayName": "Property name",
        "type": "TEXT",
        "isUnique": true,
        "defaultValue": "",
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          },
          {
            "type": "REGEX",
            "args": ["^[A-Za-z][A-Za-z0-9_.-]{0,63}$"]
          }
        ]
      },
      {
        "name": "value",
        "displayName": "Property value",
        "type": "TEXT",
        "defaultValue": ""
      }
    ],
    "newRowButtonText": "Add property",
    "help": "Up to 50 unique scalar properties for Aggregate.emit(). Use typed GTM variables for numbers, booleans, or null. The SDK and server apply consent and collection rules."
  },
  {
    "type": "CHECKBOX",
    "name": "log",
    "checkboxText": "Log failures to the console",
    "simpleValueType": true,
    "help": "Logs only in GTM preview/debug mode."
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const injectScript = require('injectScript');
const copyFromWindow = require('copyFromWindow');
const callInWindow = require('callInWindow');
const getType = require('getType');
const parseUrl = require('parseUrl');
const encodeUriComponent = require('encodeUriComponent');
const queryPermission = require('queryPermission');
const log = require('logToConsole');

const methodPath = 'Aggregate.emit';

const fail = function(message) {
  if (data.log && queryPermission('logging')) {
    log('Aggregate: ' + message);
  }
  data.gtmOnFailure();
};

// Editor validators cannot validate values supplied by GTM variables at runtime.
const httpsUrl = function(value) {
  if (getType(value) !== 'string' || value.indexOf('https://') !== 0) {
    return undefined;
  }
  for (let i = 0; i < value.length; i++) {
    if (value[i] <= ' ' || value[i] === '\\') return undefined;
  }
  const parsed = parseUrl(value);
  if (!parsed || parsed.protocol !== 'https:' || !parsed.hostname ||
      parsed.username || parsed.password || value.indexOf('#') !== -1) {
    return undefined;
  }
  return parsed;
};

const validName = function(value, maxLength, extraCharacters) {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  const characters = letters + '0123456789' + extraCharacters;
  if (getType(value) !== 'string' || !value.length || value.length > maxLength ||
      letters.indexOf(value[0]) === -1) {
    return false;
  }
  for (let i = 1; i < value.length; i++) {
    if (characters.indexOf(value[i]) === -1) return false;
  }
  return true;
};

if (data.action === 'initialize') {
  const script = httpsUrl(data.scriptUrl);
  const endpoint = httpsUrl(data.endpoint);
  if (!script || script.pathname.slice(-13) !== '/aggregate.js' ||
      (!script.search && data.scriptUrl.indexOf('?') !== -1) ||
      (script.search !== '' && script.search !== '?min=1')) {
    fail('Use an HTTPS /aggregate.js URL, optionally with ?min=1.');
    return;
  }
  if (!endpoint || getType(data.websiteToken) !== 'string' ||
      !data.websiteToken.trim()) {
    fail('Provide an HTTPS collector endpoint and a public website token.');
    return;
  }
  const encodedEndpoint = encodeUriComponent(data.endpoint);
  const encodedToken = encodeUriComponent(data.websiteToken);
  if (encodedEndpoint === undefined || encodedToken === undefined) {
    fail('The collector endpoint or website token cannot be encoded.');
    return;
  }
  // Script URL parameters configure the SDK before its automatic page view.
  const url = data.scriptUrl + (script.search ? '&' : '?') +
    'endpoint=' + encodedEndpoint + '&token=' + encodedToken;
  if (!queryPermission('inject_script', url)) {
    fail('The SDK URL is not allowed by the template script permission.');
    return;
  }
  injectScript(url, function() {
    if (getType(copyFromWindow(methodPath)) !== 'function') {
      fail('SDK method Aggregate.emit was not found. Check the script and namespace.');
      return;
    }
    data.gtmOnSuccess();
  }, function() {
    fail('The SDK script could not be loaded.');
  }, url);
  return;
}

if (data.action !== 'event') {
  fail('Choose Initialize SDK or Send event.');
  return;
}
if (!validName(data.eventName, 100, '_.:-')) {
  fail('Use a fixed event name of 1–100 letters, digits, underscores, dots, colons, or hyphens, starting with a letter.');
  return;
}

const rows = data.eventProperties === undefined ? [] : data.eventProperties;
if (getType(rows) !== 'array' || rows.length > 50) {
  fail('Event properties must be a table with at most 50 rows.');
  return;
}
const properties = {};
const propertyNames = [];
for (let i = 0; i < rows.length; i++) {
  const row = rows[i];
  if (getType(row) !== 'object' || !validName(row.name, 64, '_.-') ||
      row.name === 'constructor' || row.name === 'prototype' ||
      propertyNames.indexOf(row.name) !== -1) {
    fail('Use unique property names starting with a letter; prototype names are not allowed.');
    return;
  }
  const type = getType(row.value);
  if (type !== 'string' && type !== 'boolean' && type !== 'null' &&
      !(type === 'number' && row.value - row.value === 0)) {
    fail('Property values must be strings, finite numbers, booleans, or null.');
    return;
  }
  properties[row.name] = row.value;
  propertyNames.push(row.name);
}
if (getType(copyFromWindow(methodPath)) !== 'function') {
  fail('Initialize the SDK before sending events. Expected Aggregate.emit.');
  return;
}
const result = rows.length
  ? callInWindow(methodPath, data.eventName, properties)
  : callInWindow(methodPath, data.eventName);
if (result === false) {
  fail('The SDK rejected the event name. Use a fixed, non-identifying name.');
  return;
}
data.gtmOnSuccess();


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "inject_script",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://analytics.example.com/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "Aggregate.emit"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: initializes the configured SDK without emitting an extra page view
  code: |-
    mock('queryPermission', function() { return true; });
    const expectedUrl = 'https://analytics.example.com/aggregate.js?endpoint=https%3A%2F%2Fcollector.example.com%2Fapi%2Freceive&token=public%2Btoken%26value';
    mock('injectScript', function(url, onSuccess, onFailure, cacheToken) {
      assertThat(url).isEqualTo(expectedUrl);
      assertThat(cacheToken).isEqualTo(expectedUrl);
      onSuccess();
    });
    mock('copyFromWindow', function(path) {
      assertThat(path).isEqualTo('Aggregate.emit');
      return function() {};
    });
    runCode({action: 'initialize', scriptUrl: 'https://analytics.example.com/aggregate.js',
      endpoint: 'https://collector.example.com/api/receive', websiteToken: 'public+token&value'});
    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
    assertApi('callInWindow').wasNotCalled();
- name: preserves the minified route and deployment path prefix
  code: |-
    mock('queryPermission', function() { return true; });
    const expectedUrl = 'https://analytics.example.com/metrics/aggregate.js?min=1&endpoint=https%3A%2F%2Fanalytics.example.com%2Fmetrics%2Fapi%2Freceive&token=public-token';
    mock('injectScript', function(url, onSuccess, onFailure, cacheToken) {
      assertThat(url).isEqualTo(expectedUrl);
      assertThat(cacheToken).isEqualTo(expectedUrl);
      onSuccess();
    });
    mock('copyFromWindow', function() { return function() {}; });
    runCode({action: 'initialize', scriptUrl: 'https://analytics.example.com/metrics/aggregate.js?min=1',
      endpoint: 'https://analytics.example.com/metrics/api/receive', websiteToken: 'public-token'});
    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
- name: rejects unsupported script URLs before loading
  code: |-
    const invalidUrls = [undefined, null, 42, '', 'http://analytics.example.com/aggregate.js',
      'https://analytics.example.com/other.js', 'https://analytics.example.com/aggregate.js?min=0',
      'https://analytics.example.com/aggregate.js?token=override',
      'https://analytics.example.com/aggregate.js?consent=1',
      'https://analytics.example.com/aggregate.js?',
      'https://analytics.example.com/aggregate.js#fragment',
      'https://user:password@analytics.example.com/aggregate.js',
      'https://analytics.example.com/aggregate.js\n',
      'https://analytics.example.com\\aggregate.js'];
    for (let i = 0; i < invalidUrls.length; i++) {
      runCode({action: 'initialize', scriptUrl: invalidUrls[i],
        endpoint: 'https://analytics.example.com/api/receive', websiteToken: 'public-token'});
      assertApi('injectScript').wasNotCalled();
      assertApi('gtmOnFailure').wasCalled();
      assertApi('gtmOnSuccess').wasNotCalled();
    }
- name: requires a valid HTTPS collector endpoint
  code: |-
    const invalidEndpoints = [undefined, null, 42, '', '/api/receive', 'http://analytics.example.com/api/receive',
      'https://user:password@analytics.example.com/api/receive', 'https://analytics.example.com/api/receive#fragment'];
    for (let i = 0; i < invalidEndpoints.length; i++) {
      runCode({action: 'initialize', scriptUrl: 'https://analytics.example.com/aggregate.js',
        endpoint: invalidEndpoints[i], websiteToken: 'public-token'});
      assertApi('injectScript').wasNotCalled();
      assertApi('gtmOnFailure').wasCalled();
      assertApi('gtmOnSuccess').wasNotCalled();
    }
- name: requires a nonblank public website token
  code: |-
    const invalidTokens = [undefined, null, false, 42, '', '   '];
    for (let i = 0; i < invalidTokens.length; i++) {
      runCode({action: 'initialize', scriptUrl: 'https://analytics.example.com/aggregate.js',
        endpoint: 'https://analytics.example.com/api/receive', websiteToken: invalidTokens[i]});
      assertApi('injectScript').wasNotCalled();
      assertApi('gtmOnFailure').wasCalled();
      assertApi('gtmOnSuccess').wasNotCalled();
    }
- name: fails if configuration cannot be URL encoded
  code: |-
    mock('encodeUriComponent', function() { return undefined; });
    runCode({action: 'initialize', scriptUrl: 'https://analytics.example.com/aggregate.js',
      endpoint: 'https://analytics.example.com/api/receive', websiteToken: 'public-token'});
    assertApi('injectScript').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: fails cleanly when script permission is narrowed to another host
  code: |-
    mock('queryPermission', function(permission, url) {
      assertThat(permission).isEqualTo('inject_script');
      assertThat(url).isEqualTo('https://analytics.example.com/aggregate.js?endpoint=https%3A%2F%2Fanalytics.example.com%2Fapi%2Freceive&token=public-token');
      return false;
    });
    runCode({action: 'initialize', scriptUrl: 'https://analytics.example.com/aggregate.js',
      endpoint: 'https://analytics.example.com/api/receive', websiteToken: 'public-token'});
    assertApi('injectScript').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: fails when the SDK cannot be downloaded
  code: |-
    mock('queryPermission', function() { return true; });
    mock('injectScript', function(url, onSuccess, onFailure) { onFailure(); });
    runCode({action: 'initialize', scriptUrl: 'https://analytics.example.com/aggregate.js',
      endpoint: 'https://analytics.example.com/api/receive', websiteToken: 'public-token'});
    assertApi('copyFromWindow').wasNotCalled();
    assertApi('callInWindow').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: fails initialization when the SDK emit method is not callable
  code: |-
    mock('queryPermission', function() { return true; });
    mock('injectScript', function(url, onSuccess) { onSuccess(); });
    mock('copyFromWindow', function() { return 'not a function'; });
    runCode({action: 'initialize', scriptUrl: 'https://analytics.example.com/aggregate.js',
      endpoint: 'https://analytics.example.com/api/receive', websiteToken: 'public-token'});
    assertApi('callInWindow').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: emits an event with typed scalar properties
  code: |-
    mock('copyFromWindow', function(path) {
      assertThat(path).isEqualTo('Aggregate.emit');
      return function() {};
    });
    mock('callInWindow', function() { return true; });
    runCode({action: 'event', eventName: 'signup_completed', eventProperties: [
      {name: 'plan', value: 'pro'}, {name: 'amount', value: 0},
      {name: 'trial', value: false}, {name: 'coupon', value: null},
      {name: 'context.source', value: 'gtm'}, {name: 'toString', value: 'literal'}
    ]});
    assertApi('callInWindow').wasCalledWith('Aggregate.emit', 'signup_completed', {
      plan: 'pro', amount: 0, trial: false, coupon: null, 'context.source': 'gtm', toString: 'literal'
    });
    assertApi('injectScript').wasNotCalled();
    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
- name: omits the properties argument for an absent or empty table
  code: |-
    mock('copyFromWindow', function() { return function() {}; });
    mock('callInWindow', function() { return true; });
    runCode({action: 'event', eventName: 'signup_click'});
    assertApi('callInWindow').wasCalledWith('Aggregate.emit', 'signup_click');
    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
    runCode({action: 'event', eventName: 'signup_click', eventProperties: []});
    assertApi('callInWindow').wasCalledWith('Aggregate.emit', 'signup_click');
    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
- name: requires initialization before sending an event
  code: |-
    mock('copyFromWindow', function() { return undefined; });
    runCode({action: 'event', eventName: 'signup_click'});
    assertApi('injectScript').wasNotCalled();
    assertApi('callInWindow').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: propagates SDK rejection of an identifier like event name
  code: |-
    mock('copyFromWindow', function() { return function() {}; });
    mock('callInWindow', function() { return false; });
    runCode({action: 'event', eventName: 'customer_123456'});
    assertApi('callInWindow').wasCalledWith('Aggregate.emit', 'customer_123456');
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: rejects invalid event names before accessing the SDK
  code: |-
    const invalidNames = [undefined, null, 42, '', ' ', 'Signup Completed', '1signup', 'signup/path',
      'signup\n', 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvw'];
    for (let i = 0; i < invalidNames.length; i++) {
      runCode({action: 'event', eventName: invalidNames[i]});
      assertApi('copyFromWindow').wasNotCalled();
      assertApi('callInWindow').wasNotCalled();
      assertApi('gtmOnFailure').wasCalled();
      assertApi('gtmOnSuccess').wasNotCalled();
    }
- name: rejects invalid property tables and reserved or duplicate keys
  code: |-
    const invalidTables = [null, 'plan=pro', {}, [null], [{name: '', value: 'pro'}],
      [{name: 'two words', value: 'pro'}], [{name: '__proto__', value: 'pro'}],
      [{name: 'constructor', value: 'pro'}], [{name: 'prototype', value: 'pro'}],
      [{name: 'plan', value: 'pro'}, {name: 'plan', value: 'basic'}],
      [{name: 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklm', value: 'pro'}]];
    for (let i = 0; i < invalidTables.length; i++) {
      runCode({action: 'event', eventName: 'signup_click', eventProperties: invalidTables[i]});
      assertApi('callInWindow').wasNotCalled();
      assertApi('gtmOnFailure').wasCalled();
      assertApi('gtmOnSuccess').wasNotCalled();
    }
- name: rejects nested undefined and nonfinite property values
  code: |-
    const invalidValues = [undefined, [], {}, function() {}, 0 / 0, 1 / 0, -1 / 0];
    for (let i = 0; i < invalidValues.length; i++) {
      runCode({action: 'event', eventName: 'signup_click',
        eventProperties: [{name: 'plan', value: invalidValues[i]}]});
      assertApi('callInWindow').wasNotCalled();
      assertApi('gtmOnFailure').wasCalled();
      assertApi('gtmOnSuccess').wasNotCalled();
    }
- name: accepts 50 properties
  code: |-
    mock('copyFromWindow', function() { return function() {}; });
    mock('callInWindow', function() { return true; });
    const rows = [];
    for (let i = 0; i < 50; i++) rows.push({name: 'property' + i, value: i});
    runCode({action: 'event', eventName: 'signup_click', eventProperties: rows});
    assertApi('callInWindow').wasCalled();
    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
- name: rejects more than 50 properties
  code: |-
    const rows = [];
    for (let i = 0; i < 51; i++) rows.push({name: 'property' + i, value: i});
    runCode({action: 'event', eventName: 'signup_click', eventProperties: rows});
    assertApi('callInWindow').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: rejects an unknown action
  code: |-
    runCode({action: 'other'});
    assertApi('injectScript').wasNotCalled();
    assertApi('callInWindow').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: logs a failure when requested and logging is permitted
  code: |-
    mock('queryPermission', function(permission) {
      assertThat(permission).isEqualTo('logging');
      return true;
    });
    runCode({action: 'event', eventName: '', log: true});
    assertApi('logToConsole').wasCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: does not log when logging is disabled
  code: |-
    runCode({action: 'event', eventName: '', log: false});
    assertApi('logToConsole').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: does not log when logging permission is denied
  code: |-
    mock('queryPermission', function() { return false; });
    runCode({action: 'event', eventName: '', log: true});
    assertApi('logToConsole').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();


___NOTES___

Uses the configured Aggregate SDK route and default Aggregate.emit namespace.
Initialize once per page and sequence custom event tags after SDK loading.
