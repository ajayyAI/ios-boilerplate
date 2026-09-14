Ticket: <!-- link, or delete this line -->

## Description

<!-- Short description of the changes made, focused on the reasoning behind the choices. -->

## How to test

<!-- Steps to validate the changes. -->

## Verification

<!-- Paste the real output of `make check`. "Tests pass" without a run is a claim, not a result. -->

```
```

- [ ] **`make check` passes** locally, output pasted above.
- [ ] **Env gating holds.** A clone with no `Config/Secrets.xcconfig` still builds, runs and tests green and contacts no vendor. New integration? Protocol + no-op in `Core/`, a branch in `AppEnvironment`, a key in `AppConfig`, `Info.plist` and `Config/Secrets.example.xcconfig`, and a test that the absent key selects the no-op.
- [ ] **Tests added or updated** for the behaviour changed — or a note below saying why none apply.
- [ ] **Entitlement reads stay fail-closed.** A failed read shows a retry, never the gated content.

## Checklist

- [ ] **Usable and accessible.** Supports dark mode, Dynamic Type, VoiceOver.
- [ ] **Secure.** Respects user privacy; no secrets committed.
- [ ] **Localised.** Any new strings added to the string catalog.
- [ ] **Architecture.** Follows `docs/architecture.md` — dependencies point inward, layers earn their place.
- [ ] **Performant.** No obvious regressions.
