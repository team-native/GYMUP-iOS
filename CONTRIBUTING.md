# Contributing

## Branches

Create feature branches from `dev` and include the GitHub issue number:

- `feat/#12-short-description`
- `fix/#13-short-description`
- `chore/#14-short-description`

Keep each branch focused on one issue. Do not commit directly to `dev`.

## Commits

Use a conventional type and include the issue number when applicable:

```text
feat: [#12] add workout summary
fix: [#13] preserve selected training date
chore: [#14] update project tooling
```

Use `feat`, `fix`, `refactor`, `test`, `docs`, or `chore`, followed by a concise imperative summary.

## Pull requests

- Target `dev`.
- Link the issue with `Closes #<number>` when the PR completes it.
- Describe the change and list build, test, lint, and runtime checks separately.
- Complete the repository pull-request template.
- Keep merge decisions with the repository maintainers; CI does not auto-merge.

## Local checks

```sh
tuist generate --no-open
swiftlint lint --strict
xcodebuild test -project GYMUP.xcodeproj -scheme GYMUP \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```
