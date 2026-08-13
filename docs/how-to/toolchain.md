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

## macOS setup

Xcode supplies the Apple SDKs and Swift toolchain. Install the auxiliary command-line tools declared in `Brewfile` with:

```bash
make bootstrap
```

Then lint files changed from `HEAD` without modifying them:

```bash
make lint
```

Changed-file linting keeps existing cleanup debt from blocking unrelated work. Use `make lint-all` to audit the whole repository.

Run `make format` separately when an intentional repository-wide formatting change is desired. Generated OpenAPI client files are excluded from formatting and linting.

## Swift package checks

`PeatedAPI` can be tested anywhere its Swift dependencies support the host:

```bash
make test-api
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

## Limited environments

Run every applicable verification tier. If Swift, Xcode, a simulator, or an MCP build tool is unavailable, report that portion as unverified and include the checks that did run. Tool absence is not itself a build failure.

## Tool references

- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) defines the `.swiftformat` configuration and formatting checks.
- [SwiftLint](https://github.com/realm/SwiftLint) defines the `.swiftlint.yml` static-analysis rules.
- [ShellCheck](https://github.com/koalaman/shellcheck) performs static analysis of Bash scripts.
