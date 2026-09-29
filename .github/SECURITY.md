# Security Policy

## Supported Versions

Only the latest published version of the Aggregate Google Tag Manager template is actively supported for security updates.

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| Older   | :x:                |

## Reporting a Vulnerability

We take the security of Aggregate and its integrations seriously. If you discover or suspect a security vulnerability in this template, please report it responsibly.

### How to Report

1. **GitHub Private Vulnerability Reporting (Preferred):**
   Go to the [Security Advisories tab](https://github.com/Subschema-LLC/aggregate-gtm-tag-template/security/advisories/new) on GitHub and click **"Report a vulnerability"**. This allows us to collaborate privately before publishing a fix.

2. **Email:**
   If you are unable to use GitHub Security Advisories, send details to **security@subschema.com** (or contact the maintainers directly).

### What to Include

Please provide:
- A description of the vulnerability and its potential impact.
- Step-by-step reproduction instructions or a minimal proof of concept (PoC).
- Any specific configuration or GTM environment settings involved.

### What Not to Report as a Vulnerability

- **Public Website Tokens:** Public website tokens configured in the template are designed to be client-visible and sent in network requests. They identify event-source websites and are not administrative secrets. Do not configure organization sharing tokens or API master secrets in GTM tags.
- **Console Warnings in Debug Mode:** Debug-mode logging when enabled is designed for developer troubleshooting and is restricted to GTM Preview mode.

### Our Commitment

- We will acknowledge receipt of your vulnerability report within 48 hours.
- We will provide an estimated timeline for evaluation and remediation.
- We will coordinate public disclosure after a patch is tested and released.
