# Development Toolchain

This guide defines the supported verification commands for Linux and macOS.

Status: active

## Selected versions

- Xcode: read `.xcode-version` (`26.6`)
- Swift container: 6.3 on Ubuntu Jammy, pinned by image digest
- SwiftFormat container: 0.63.0, pinned by image digest
- SwiftLint container: 0.65.1, pinned by image digest
- App Store Connect CLI: 5.0.0 in automation; Homebrew provides local updates
- actionlint: 1.7.12, pinned by container digest in CI

The Makefile and CI workflow are the executable sources of truth for these versions. `make doctor` reports the selected local Xcode and warns when it differs.

## Command entry point

Run `make help` from the repository root. Start by inspecting the host:

```bash
make doctor
```

## Portable checks

Run repository checks on Linux or macOS:

```bash
make check
make lint-actions-docker
```

The command checks shell and JSON syntax, the app privacy manifest, agent-instruction mirrors, merge markers, and changed-line whitespace. It does not compile Swift.

Linux hosts with Docker can use the pinned tool images:

```bash
make lint-docker
make format-check-docker
make lint-swift-docker
make test-api-docker
```

Generated OpenAPI sources and the executable `Scripts/recolor-png.swift` helper are excluded from formatting.

## macOS setup

Install the Xcode version in `.xcode-version`. Select it with `xcode-select`, then install auxiliary tools:

```bash
make bootstrap
make doctor
```

Lint files changed from `HEAD` without modifying them:

```bash
make lint
```

Set `LINT_BASE_REF` to compare with another commit or branch. CI uses the pull-request base SHA.

Use `make lint-all` for repository-wide native lint and formatting checks. Use `make format` only for an intentional formatting change.

After removing existing SwiftLint violations, regenerate the reviewed baseline with:

```bash
make update-swiftlint-baseline
```

Review the baseline diff. Routine cleanup should remove entries; additions expand accepted debt and need explicit review.

## Swift packages

Run package tests on an Apple host:

```bash
make test-api
make test-core
make test-packages
```

`PeatedCore` imports Apple-platform dependencies and requires an Apple toolchain. `PeatedAPI` is also tested in Linux CI with the pinned Swift image.

The checked-in `Package.resolved` files define the reviewed dependency graph. Routine build and test commands do not update that graph. Update dependencies deliberately and review the resolved-file diff.

## iOS verification

The local command-line fallback uses `iPhone 16 Pro`:

```bash
make build-ios
make test-ios
```

`make test-ios` writes `.test-results/Peated.xcresult`. GitHub Actions uploads this bundle for seven days so failures can be opened in Xcode.

Agents should prefer XcodeBuildMCP when it is available because it can build, launch, inspect accessibility state, capture logs, and take screenshots. Use semantic accessibility queries before coordinate-based interaction.

Run the full Apple-host suite with:

```bash
make verify
```

## GitHub Actions

The `CI` workflow runs for pull requests and pushes to `main`:

- `Repository checks` runs portable validation, SwiftLint, SwiftFormat, ShellCheck, and `PeatedAPI` tests on Ubuntu.
- `PeatedCore package tests` runs on macOS 26 with Xcode 26.6.
- `iOS app tests` runs on macOS 26 with Xcode 26.6 and an installed `iPhone 17 Pro` simulator.
- `Apple build and tests` provides one stable aggregate branch-protection check.

The workflow uses read-only repository permissions, cancels superseded runs, pins third-party actions to reviewed commits, and caches dependency-compatible build products.

Dependabot updates GitHub Actions plus the `PeatedAPI` and `PeatedCore` Swift package manifests. Xcode-project package requirements still need a deliberate manual update because Dependabot does not manage package requirements stored in `project.pbxproj`.

## Xcode Cloud

Xcode Cloud is reserved for manual release archives and TestFlight distribution. GitHub Actions provides the per-change Apple build and test gate without consuming Xcode Cloud compute hours.

Use `make xcode-cloud-list` to inspect workflows and `make xcode-cloud-run ASC_XCODE_CLOUD_WORKFLOW='<name>'` to start the release workflow. The manual `Xcode Cloud` GitHub Actions workflow provides the same operation from the repository UI.

Xcode Cloud uses the committed app `Package.resolved`. Its post-clone script validates that the lockfile exists and does not clear caches, delete lockfiles, or update dependencies. See `@docs/how-to/app-store-connect.md` for credentials, workflow settings, and release operation.

## Limited environments

Run every applicable verification tier. If Swift, Xcode, a simulator, or an MCP build tool is unavailable, report that portion as unverified. Missing tooling is not itself a build failure.

## References

- [Building apps with Swift packages in CI](https://developer.apple.com/documentation/xcode/building-swift-packages-or-apps-that-use-them-in-continuous-integration-workflows)
- [Xcode system requirements](https://developer.apple.com/xcode/system-requirements)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- [SwiftLint](https://github.com/realm/SwiftLint)
- [ShellCheck](https://github.com/koalaman/shellcheck)
- [App Store Connect CLI](https://github.com/rorkai/App-Store-Connect-CLI)
- [actionlint](https://github.com/rhysd/actionlint)
