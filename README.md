# aggregate-gtm-tag-template

Google Tag Manager community template for the Aggregate browser SDK.

## Files

- `template.tpl` - GTM custom template export for loading the Aggregate SDK and sending an event
- `metadata.yaml` - GTM gallery metadata and release notes

## How to use

1. Import the repository's `template.tpl` into a web container as a custom template.
2. Create a tag from the imported **Aggregate** template.
3. Set the **Aggregate script URL** to an Aggregate-published SDK URL from a supported origin:
   - `https://cdn.jsdelivr.net/gh/Subschema-LLC/aggregate...`
   - `https://raw.githubusercontent.com/Subschema-LLC/aggregate/...`
4. Set the **Event name** and any optional event properties.
5. Attach the trigger that should fire the Aggregate event.

## Current template behavior

The initial template keeps the integration intentionally small:

- it loads the Aggregate browser SDK from a configurable HTTPS `.js` URL
- it expects the SDK to expose `window.aggregate.track`
- it calls `aggregate.track(eventName, properties)` when the tag fires

This keeps the template usable while the Aggregate SDK distribution URL and any additional configuration requirements are finalized.
