SHELL := /bin/bash

PROJECT := Peated/Peated.xcodeproj
SCHEME := Peated
SIMULATOR := iPhone 16 Pro
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)
DERIVED_DATA := .derived_data
RESULT_BUNDLE ?= .test-results/Peated.xcresult
SWIFT_DOCKER_IMAGE := swift:6.3-jammy@sha256:a05aa080e573b1f7e10bd630ce9e1d7645abb08a32d1def73cb611ac708d2a8a
ASC_APP_ID ?= com.peated.Peated
ASC_XCODE_CLOUD_WORKFLOW ?=
XCODE_CLOUD_BRANCH ?= main
XCODE_CLOUD_TIMEOUT ?= 2h

.DEFAULT_GOAL := help

SWIFTFORMAT_IMAGE ?= ghcr.io/nicklockwood/swiftformat:0.63.0@sha256:cb50a33496b4f5123b99241437f24f154a68085398cfda1412ed3b6bab9c02ec
SWIFTLINT_IMAGE ?= ghcr.io/realm/swiftlint:0.65.1@sha256:f47e083201e47a136cda5ae847595bfe00226c444ca226fa74fa5dc648a9b057
ACTIONLINT_IMAGE ?= rhysd/actionlint:1.7.12@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667

.PHONY: help doctor bootstrap check lint lint-docker lint-all lint-swift \
	lint-actions lint-actions-docker \
	lint-swift-docker lint-shell update-swiftlint-baseline format format-docker \
	format-check format-check-docker \
	test-api test-api-docker test-core test-packages build-ios \
	test-ios verify xcode-cloud-list xcode-cloud-run

help:
	@printf '%s\n' \
		'Peated development commands' \
		'' \
		'  make doctor        Show available toolchain capabilities' \
		'  make bootstrap     Install macOS command-line tools with Homebrew' \
		'  make check         Run portable repository checks' \
		'  make lint          Lint files changed from HEAD' \
		'  make lint-docker   Lint changed files with pinned Linux containers' \
		'  make lint-all      Check all hand-written source files' \
		'  make lint-actions  Validate GitHub Actions workflows' \
		'  make lint-actions-docker  Validate workflows with the pinned container' \
		'  make lint-swift-docker  Check all Swift files against the baseline' \
		'  make update-swiftlint-baseline  Regenerate the reviewed lint baseline' \
		'  make format        Format hand-written Swift sources' \
		'  make format-docker  Format Swift sources with the pinned container' \
		'  make format-check  Check repository-wide Swift formatting' \
		'  make format-check-docker  Check formatting with the pinned container' \
		'  make test-api      Test the PeatedAPI Swift package' \
		'  make test-api-docker  Test PeatedAPI with the pinned Linux toolchain' \
		'  make test-core     Test the PeatedCore Swift package (Apple host)' \
		'  make test-packages Test both Swift packages (Apple host)' \
		'  make build-ios     Build the iOS app for iPhone 16 Pro' \
		'  make test-ios      Test the iOS app on iPhone 16 Pro' \
		'  make xcode-cloud-list  List configured Xcode Cloud workflows' \
		'  make xcode-cloud-run   Manually run the selected Xcode Cloud workflow' \
		'  make verify        Run the full macOS verification suite'

doctor:
	@./Scripts/doctor.sh

bootstrap:
	@if [ "$$(uname -s)" != 'Darwin' ]; then \
		echo 'error: make bootstrap currently supports macOS only' >&2; \
		exit 1; \
	fi
	@command -v brew >/dev/null 2>&1 || { \
		echo 'error: Homebrew is required: https://brew.sh' >&2; \
		exit 1; \
	}
	brew bundle --file Brewfile

check:
	@./Scripts/check-repository.sh

lint:
	@./Scripts/lint-changed.sh

lint-docker:
	@./Scripts/lint-changed-docker.sh

lint-all: lint-swift lint-shell format-check

lint-actions:
	@command -v actionlint >/dev/null 2>&1 || { \
		echo 'error: actionlint is unavailable; run make bootstrap on macOS' >&2; \
		exit 1; \
	}
	actionlint

lint-actions-docker:
	@command -v docker >/dev/null 2>&1 || { \
		echo 'error: docker is required for containerized workflow linting' >&2; \
		exit 1; \
	}
	docker run --rm -v "$(CURDIR):/repo:ro" -w /repo "$(ACTIONLINT_IMAGE)"

lint-swift:
	@command -v swiftlint >/dev/null 2>&1 || { \
		echo 'error: swiftlint is unavailable; run make bootstrap on macOS' >&2; \
		exit 1; \
	}
	swiftlint lint --config .swiftlint.yml --baseline .swiftlint-baseline.json

lint-swift-docker:
	@command -v docker >/dev/null 2>&1 || { \
		echo 'error: docker is required for containerized linting' >&2; \
		exit 1; \
	}
	docker run --rm -v "$(CURDIR):/work:ro" -w /work "$(SWIFTLINT_IMAGE)" \
		lint --config /work/.swiftlint.yml --baseline /work/.swiftlint-baseline.json

update-swiftlint-baseline:
	@./Scripts/update-swiftlint-baseline.sh

lint-shell:
	@command -v shellcheck >/dev/null 2>&1 || { \
		echo 'error: shellcheck is unavailable; run make bootstrap on macOS' >&2; \
		exit 1; \
	}
	@git ls-files -z '*.sh' | xargs -0 shellcheck

format:
	@command -v swiftformat >/dev/null 2>&1 || { \
		echo 'error: swiftformat is unavailable; run make bootstrap on macOS' >&2; \
		exit 1; \
	}
	swiftformat Peated PeatedCore PeatedAPI Scripts --config .swiftformat

format-docker:
	@command -v docker >/dev/null 2>&1 || { \
		echo 'error: docker is required for containerized formatting' >&2; \
		exit 1; \
	}
	docker run --rm --user "$$(id -u):$$(id -g)" \
		-v "$(CURDIR):/work" -w /work "$(SWIFTFORMAT_IMAGE)" \
		Peated PeatedCore PeatedAPI Scripts --config /work/.swiftformat --cache ignore

format-check:
	@command -v swiftformat >/dev/null 2>&1 || { \
		echo 'error: swiftformat is unavailable; run make bootstrap on macOS' >&2; \
		exit 1; \
	}
	swiftformat Peated PeatedCore PeatedAPI Scripts --config .swiftformat --lint

format-check-docker:
	@command -v docker >/dev/null 2>&1 || { \
		echo 'error: docker is required for containerized formatting' >&2; \
		exit 1; \
	}
	docker run --rm -v "$(CURDIR):/work:ro" -w /work "$(SWIFTFORMAT_IMAGE)" \
		Peated PeatedCore PeatedAPI Scripts --config /work/.swiftformat --lint --cache ignore

test-api:
	@command -v swift >/dev/null 2>&1 || { \
		echo 'error: swift is unavailable; install a Swift 6 toolchain' >&2; \
		exit 1; \
	}
	cd PeatedAPI && swift test

test-api-docker:
	@command -v docker >/dev/null 2>&1 || { \
		echo 'error: docker is required for containerized Swift tests' >&2; \
		exit 1; \
	}
	docker run --rm --user "$$(id -u):$$(id -g)" -e HOME=/tmp \
		-v "$(CURDIR):/work" -w /work/PeatedAPI "$(SWIFT_DOCKER_IMAGE)" swift test

test-core:
	@./Scripts/require-apple-toolchain.sh swift
	cd PeatedCore && swift test

test-packages: test-api test-core

build-ios:
	@./Scripts/require-apple-toolchain.sh xcodebuild
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		-disableAutomaticPackageResolution \
		-destination '$(DESTINATION)' build

test-ios:
	@./Scripts/require-apple-toolchain.sh xcodebuild
	@mkdir -p "$(dir $(RESULT_BUNDLE))"
	@rm -rf "$(RESULT_BUNDLE)"
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		-resultBundlePath "$(RESULT_BUNDLE)" \
		-disableAutomaticPackageResolution \
		-destination '$(DESTINATION)' \
		-parallel-testing-enabled NO test

xcode-cloud-list:
	@command -v asc >/dev/null 2>&1 || { \
		echo 'error: asc is unavailable; run make bootstrap on macOS' >&2; \
		exit 1; \
	}
	ASC_TELEMETRY_DISABLED=1 asc xcode-cloud workflows list \
		--app "$(ASC_APP_ID)" --paginate --output table

xcode-cloud-run:
	@command -v asc >/dev/null 2>&1 || { \
		echo 'error: asc is unavailable; run make bootstrap on macOS' >&2; \
		exit 1; \
	}
	@test -n "$(ASC_XCODE_CLOUD_WORKFLOW)" || { \
		echo 'error: set ASC_XCODE_CLOUD_WORKFLOW to the workflow name' >&2; \
		exit 1; \
	}
	ASC_TELEMETRY_DISABLED=1 asc xcode-cloud run \
		--app "$(ASC_APP_ID)" \
		--workflow "$(ASC_XCODE_CLOUD_WORKFLOW)" \
		--branch "$(XCODE_CLOUD_BRANCH)" \
		--wait --timeout "$(XCODE_CLOUD_TIMEOUT)" --output table

verify: check lint test-packages test-ios
