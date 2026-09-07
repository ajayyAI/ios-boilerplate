# Security

## Reporting a vulnerability

Report privately through GitHub security advisories:
[open a draft advisory](https://github.com/ajayyAI/ios-boilerplate/security/advisories/new).
Do not open a public issue for a vulnerability.

Include the affected file or commit, reproduction steps, and what an attacker gains.
Reports go to the repository owner, `@ajayyai`.

There are no maintained release branches. Fixes land on `main`; an app cloned from this
starter has to pull them in itself.

## An xcconfig is not a secret store

`Config/Secrets.xcconfig` is gitignored, which keeps keys out of git history and away
from contributors. It does nothing for the shipped binary. Anything reaching the app
through `Info.plist` or a build setting is baked into the bundle and recoverable with
`strings`, a disassembler, or a proxy. OWASP MAS covers this as
[MASWE-0005](https://mas.owasp.org/MASWE/MASVS-AUTH/MASWE-0005/).

Gitignore protects the repository. It does not protect the credential.

## Keys that do not belong in the client

Any key that authorizes real spend or reads user data belongs behind a backend you
control: the server holds the real credential, the app receives short-lived scoped
tokens, and
[App Attest](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity)
verifies the request came from a genuine build of your app.

## What is not a vulnerability

The keys this starter ships support are publishable client keys, designed to be
extractable from a client:

- `REVENUECAT_API_KEY` — RevenueCat SDK key
- `SENTRY_DSN` — Sentry DSN
- `POSTHOG_API_KEY` — PostHog project key

Recovering one of these from an app binary is not a vulnerability in this project.
Report it upstream to the vendor if you believe otherwise.

See [`docs/configuration.md`](docs/configuration.md) for the full configuration model.
