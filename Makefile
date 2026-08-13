SHELL := /bin/bash

PROJECT := Peated/Peated.xcodeproj
SCHEME := Peated
SIMULATOR := iPhone 16 Pro
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR),OS=latest

.DEFAULT_GOAL := help

.PHONY: help doctor bootstrap check lint lint-docker lint-all lint-swift lint-shell \
	format format-check test-api test-core test-packages build-ios test-ios verify

help:
	@printf '%s\n' \
		'Peated development commands' \
		'' \
		'  make doctor        Show available toolchain capabilities' \
		'  make bootstrap     Install macOS command-line tools with Homebrew' \
		'  make check         Run portable repository checks' \
		'  make lint          Lint files changed from HEAD' \
		'  make lint-docker   Lint changed files with pinned Linux containers' \
		'  make lint-all      Audit all hand-written source files' \
		'  make format        Format hand-written Swift sources' \
		'  make format-check  Check repository-wide Swift formatting' \
		'  make test-api      Test the PeatedAPI Swift package' \
		'  make test-core     Test the PeatedCore Swift package (Apple host)' \
		'  make test-packages Test both Swift packages (Apple host)' \
		'  make build-ios     Build the iOS app for iPhone 16 Pro' \
		'  make test-ios      Test the iOS app on iPhone 16 Pro' \
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

lint-swift:
	@command -v swiftlint >/dev/null 2>&1 || { \
		echo 'error: swiftlint is unavailable; run make bootstrap on macOS' >&2; \
		exit 1; \
	}
	swiftlint lint --config .swiftlint.yml

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

format-check:
	@command -v swiftformat >/dev/null 2>&1 || { \
		echo 'error: swiftformat is unavailable; run make bootstrap on macOS' >&2; \
		exit 1; \
	}
	swiftformat Peated PeatedCore PeatedAPI Scripts --config .swiftformat --lint

test-api:
	@command -v swift >/dev/null 2>&1 || { \
		echo 'error: swift is unavailable; install a Swift 6 toolchain' >&2; \
		exit 1; \
	}
	cd PeatedAPI && swift test

test-core:
	@./Scripts/require-apple-toolchain.sh swift
	cd PeatedCore && swift test

test-packages: test-api test-core

build-ios:
	@./Scripts/require-apple-toolchain.sh xcodebuild
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" \
		-destination '$(DESTINATION)' build

test-ios:
	@./Scripts/require-apple-toolchain.sh xcodebuild
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" \
		-destination '$(DESTINATION)' test

verify: check lint test-packages test-ios
