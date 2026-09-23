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
  "description": "Loads the Aggregate browser SDK and tracks an event with optional properties.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "scriptUrl",
    "displayName": "Aggregate script URL",
    "simpleValueType": true,
    "help": "HTTPS URL for the Aggregate browser SDK bundle.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      },
      {
        "type": "REGEX",
        "args": [
          "^https://(cdn\\.jsdelivr\\.net/gh/Subschema-LLC/aggregate.*\\.js(\\?.*)?|raw\\.githubusercontent\\.com/Subschema-LLC/aggregate/.*\\.js(\\?.*)?)$"
        ]
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "eventName",
    "displayName": "Event name",
    "simpleValueType": true,
    "help": "Name passed to aggregate.track().",
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "eventProperties",
    "displayName": "Event properties",
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
    "help": "Optional properties to pass as the second aggregate.track() argument."
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
const makeTableMap = require('makeTableMap');
const log = require('logToConsole');

const scriptUrl = data.scriptUrl;
const methodPath = 'aggregate.track';
const eventProperties = data.eventProperties && data.eventProperties.length
  ? makeTableMap(data.eventProperties, 'name', 'value')
  : null;

const onFailure = function() {
  if (data.log) {
    log('Aggregate tag failed to load or execute.');
  }
  data.gtmOnFailure();
};

const onSuccess = function() {
  const trackMethod = copyFromWindow(methodPath);

  if (getType(trackMethod) !== 'function') {
    if (data.log) {
      log('Aggregate tracking method not found at ' + methodPath + '.');
    }
    data.gtmOnFailure();
    return;
  }

  if (eventProperties) {
    callInWindow(methodPath, data.eventName, eventProperties);
  } else {
    callInWindow(methodPath, data.eventName);
  }
  data.gtmOnSuccess();
};

injectScript(scriptUrl, onSuccess, onFailure, scriptUrl);


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
                "string": "https://cdn.jsdelivr.net/gh/Subschema-LLC/aggregate*"
              },
              {
                "type": 1,
                "string": "https://raw.githubusercontent.com/Subschema-LLC/aggregate/*"
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
                    "string": "aggregate.track"
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
- name: tracks an Aggregate event after loading the SDK
  code: |-
    const mockData = {
      scriptUrl: 'https://cdn.example.com/aggregate.js',
      eventName: 'Signup Completed',
      eventProperties: [
        {name: 'plan', value: 'pro'},
        {name: 'source', value: 'gtm'}
      ]
    };

    mock('injectScript', function(url, onSuccess, onFailure, cacheToken) {
      assertThat(url).isEqualTo('https://cdn.example.com/aggregate.js');
      assertThat(cacheToken).isEqualTo('https://cdn.example.com/aggregate.js');
      onSuccess();
    });

    mock('copyFromWindow', function(path) {
      if (path === 'aggregate.track') {
        return function() {};
      }
    });

    mock('callInWindow', function(path, eventName, properties) {
      assertThat(path).isEqualTo('aggregate.track');
      assertThat(eventName).isEqualTo('Signup Completed');
      assertThat(properties).isEqualTo({
        plan: 'pro',
        source: 'gtm'
      });
    });

    runCode(mockData);

    assertApi('gtmOnSuccess').wasCalled();
- name: omits event properties when none are configured
  code: |-
    const mockData = {
      scriptUrl: 'https://cdn.example.com/aggregate.js',
      eventName: 'Page Viewed'
    };

    mock('injectScript', function(url, onSuccess) {
      onSuccess();
    });

    mock('copyFromWindow', function(path) {
      if (path === 'aggregate.track') {
        return function() {};
      }
    });

    runCode(mockData);

    assertApi('callInWindow').wasCalledWith('aggregate.track', 'Page Viewed');
    assertApi('gtmOnSuccess').wasCalled();
- name: fails when the Aggregate tracking method is missing
  code: |-
    const mockData = {
      scriptUrl: 'https://cdn.example.com/aggregate.js',
      eventName: 'Signup Completed'
    };

    mock('injectScript', function(url, onSuccess) {
      onSuccess();
    });

    mock('copyFromWindow', function(path) {
      return undefined;
    });

    runCode(mockData);

    assertApi('callInWindow').wasNotCalled();
    assertApi('gtmOnFailure').wasCalled();
- name: fails when the Aggregate SDK script cannot be loaded
  code: |-
    const mockData = {
      scriptUrl: 'https://cdn.example.com/aggregate.js',
      eventName: 'Signup Completed'
    };

    mock('injectScript', function(url, onSuccess, onFailure) {
      onFailure();
    });

    runCode(mockData);

    assertApi('gtmOnFailure').wasCalled();


___NOTES___

Initial Aggregate GTM community template.
