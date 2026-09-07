# Contributing

This is a starter, not an app. A change lands here only if it belongs in every app
cloned from it. Product behaviour belongs in the app you build, not in the template.

## Setup

```bash
brew bundle        # SwiftLint, SwiftFormat, xcbeautify, Periphery, lefthook
lefthook install   # pre-commit, commit-msg, pre-push hooks
make check         # the gate
```

Run `make check` before you change anything. On a clean clone it passes with no vendor
accounts and no `Config/Secrets.xcconfig`. If it fails there, that is a bug in the
template — open an issue with the output.

Requires Xcode 26.6 (Swift 6.3.3). Deployment target is iOS 18.0.

Tool versions are pinned in `Brewfile` and asserted by `scripts/assert-tool-versions.sh`
(`make doctor`, the first step of `check`). Older than pinned fails; newer warns.

Do not run `scripts/rename-project.py`. That script is for someone starting an app from
this template. In a contributor clone it renames the project out from under you.

## Commits

Conventional Commits, enforced by the `commit-msg` hook
(`scripts/check-commit-msg.sh`). Format `<type>[optional scope]: <description>`, subject
capped at 72 characters. Types: `feat` `fix` `docs` `style` `refactor` `perf` `test`
`build` `ci` `chore` `revert`. Merge and revert commits are exempt.

```
feat(home): add pull to refresh
```

## Pull requests

Branch off `main`; the pre-push hook blocks pushing to `main` directly. PRs are
squash-merged, so the PR title becomes the commit subject and must also be a
Conventional Commit.

`make check` must pass before you open a PR. Paste the real output into the PR — CI runs
the identical target as a required status check named `make check`, so a failing gate
cannot merge either way. Fill in the PR template.

## What a PR is judged against

### The env-gating invariant — non-negotiable

A clone with no `Config/Secrets.xcconfig` must build, run and test green, and contact no
vendor. An absent or empty key resolves to the no-op implementation of its client.
`AppEnvironment` is the only place that decision is made — never branch on a key at a
call site. `AppEnvironmentTests` enforces this.

Adding an integration means all of: a protocol and a no-op in `Core/`, a branch in
`AppEnvironment`, a key in `AppConfig` **and** `Info.plist` **and**
`Config/Secrets.example.xcconfig`, and a test that the absent key selects the no-op.
Vendor SDKs start in `ScaffoldAppDelegate`, never in an initializer, so constructing
the composition root stays free of side effects.

A PR that breaks this is declined regardless of what else it does.

### Entitlement reads are fail-closed

A failed entitlement read shows a retry, never the gated content and never a free
unlock. `PaywallGateTests` pins this. If a change makes a failed read grant access, that
is a defect regardless of what else it fixes.

### Architecture

The rules are in [`docs/architecture.md`](docs/architecture.md) — dependency direction,
what belongs in `Presentation` / `Domain` / `Data`, and when a layer earns its place.
Read it before moving code between folders or adding a use case.

### Tests

Feature tests go in `ScaffoldTests/<Feature>/`, cross-cutting ones in
`ScaffoldTests/Sanity/`, XCUITest flows in `ScaffoldUITests/Flows/`. A feature
earns view model and use case tests before it earns a UI test.

## `make deadcode` is not in `check`

Periphery rebuilds and re-indexes, which makes it the slowest step, and a starter's
shared surface is unused by design — so it reports things that are not defects here.
Run it on demand once real features exist:

```bash
make deadcode
```

## Localizable.xcstrings

The string catalog syncs from source when you build **in Xcode**, not from `make build` —
`xcodebuild` emits the extracted strings but only the IDE writes them back into the file.
If you add user-facing text and the catalog looks stale, open the project and build once.
