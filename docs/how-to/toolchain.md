# Development Toolchain

This guide defines the supported verification commands for Linux and macOS development environments.

Status: active

## Command entry point

Run `make help` from the repository root to see the supported commands. The Makefile is the canonical command interface for local development and automation; scripts under `Scripts/` contain the implementation details.

Start by inspecting the current host:

```bash
make doctor
```

## Portable checks

The baseline repository checks require Bash, Git, and either `jq` or Apple's `plutil`:

```bash
make check
```

These checks run on Linux and macOS. They validate shell and JSON syntax, instruction-file mirrors, merge markers, and whitespace in the current diff. They do not compile Swift.

Linux hosts with Docker can lint changed Swift and shell files using pinned tool images:

```bash
make lint-docker
```

The first run downloads SwiftFormat 0.62.1, SwiftLint 0.65.0, and ShellCheck 0.11.0 images. Override `SWIFTFORMAT_IMAGE`, `SWIFTLINT_IMAGE`, or `SHELLCHECK_IMAGE` when an internally mirrored image is required.

Apply or verify repository-wide Swift formatting on Linux with the pinned formatter:

```bash
make format-docker
make format-check-docker
```

Generated OpenAPI sources and the executable `Scripts/recolor-png.swift` helper are excluded. The script retains its shebang and executable mode because SwiftFormat import sorting does not preserve them.

Run the repository-wide SwiftLint ratchet with:

```bash
make lint-swift-docker
```

`.swiftlint-baseline.json` records existing violations, while strict mode rejects every violation outside that baseline. This keeps existing cleanup debt from blocking unrelated changes without allowing the debt to grow.

## macOS setup

Xcode supplies the Apple SDKs and Swift toolchain. Install the auxiliary command-line tools declared in `Brewfile` with:

```bash
make bootstrap
```

Then lint files changed from `HEAD` without modifying them:

```bash
make lint
```

Changed-file linting applies the same strict baseline to edited Swift files. Use `make lint-all` to check all hand-written sources with native macOS tools.

Set `LINT_BASE_REF` to lint committed changes against another commit or branch. GitHub Actions uses the pull request base SHA:

```bash
LINT_BASE_REF=origin/main make lint-docker
```

Run `make format` separately when an intentional repository-wide formatting change is desired. Generated OpenAPI client files are excluded from formatting and linting.

After removing existing SwiftLint violations, regenerate the baseline with:

```bash
make update-swiftlint-baseline
```

Review the generated diff before committing it. Routine cleanup should only remove baseline entries; additions require an explicit decision because they expand accepted debt.

## Swift package checks

`PeatedAPI` can be tested anywhere its Swift dependencies support the host:

```bash
make test-api
```

Linux and CI use the pinned Swift 6.1.2 container:

```bash
make test-api-docker
```

`PeatedCore` imports Apple-platform dependencies and should be tested on macOS:

```bash
make test-core
make test-packages
```

## iOS verification

The command-line fallback uses the standard `iPhone 16 Pro` simulator:

```bash
make build-ios
make test-ios
```

Agents should prefer the repository's `xcodebuildmcp` build-and-run flow when it is available because it can also launch and inspect the app. The Make targets provide a consistent fallback for macOS hosts and CI.

Run the complete local suite with:

```bash
make verify
```

## GitHub Actions

The `CI` workflow runs for pull requests and pushes to `main`:

- `Repository checks` runs portable validation, enforces the repository-wide SwiftLint baseline, lints changed files, and runs the containerized `PeatedAPI` package tests on Ubuntu.
- `PeatedCore package tests` and `iOS app tests` run concurrently on macOS 15 with Xcode 16.4.
- `Apple build and tests` aggregates both Apple jobs so branch protection retains one stable required check.

SwiftPM build directories and Xcode DerivedData are cached with keys that include the host, toolchain, dependency manifests, lockfiles, and source hashes. A source change restores the closest dependency-compatible cache and lets SwiftPM or Xcode rebuild affected artifacts. The iOS test command disables parallel testing because the suite targets one simulator and does not benefit from cloned devices.

The workflow uses read-only repository permissions, cancels superseded runs, and pins third-party actions to reviewed commits. Dependabot checks weekly for GitHub Actions updates.

## Limited environments

Run every applicable verification tier. If Swift, Xcode, a simulator, or an MCP build tool is unavailable, report that portion as unverified and include the checks that did run. Tool absence is not itself a build failure.

## Tool references

- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) defines the `.swiftformat` configuration and formatting checks.
- [SwiftLint](https://github.com/realm/SwiftLint) defines the `.swiftlint.yml` static-analysis rules.
- [ShellCheck](https://github.com/koalaman/shellcheck) performs static analysis of Bash scripts.
