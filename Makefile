# Single entry point for verification. `make check` is the gate.
.PHONY: help doctor sim format format-check lint build test deadcode check clean

PROJECT  := Scaffold.xcodeproj
SCHEME   := Scaffold
TESTPLAN := AllTests
DEVICE   := iPhone 17
DEST     := platform=iOS Simulator,name=$(DEVICE)

help: ## Show available targets
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

doctor: ## Assert pinned tool versions are installed
	@./scripts/assert-tool-versions.sh

# XCUITest launches intermittently fail preflight with "Busy" when the simulator is
# still starting. Booting and waiting first makes runs deterministic.
sim: ## Boot the test simulator and wait for it
	@xcrun simctl boot "$(DEVICE)" 2>/dev/null || true
	@xcrun simctl bootstatus "$(DEVICE)" -b >/dev/null

format: ## Rewrite sources in place
	@swiftformat .

format-check: ## Fail if sources are unformatted
	@swiftformat . --lint

lint: ## Fail on lint violations
	@swiftlint lint --strict

build: ## Build for the simulator
	@set -o pipefail && xcodebuild build \
		-project $(PROJECT) -scheme $(SCHEME) \
		-destination '$(DEST)' | xcbeautify

test: sim ## Run the full test plan
	@rm -rf TestResults.xcresult
	@set -o pipefail && xcodebuild test \
		-project $(PROJECT) -scheme $(SCHEME) \
		-testPlan $(TESTPLAN) -destination '$(DEST)' \
		-enableCodeCoverage YES \
		-resultBundlePath TestResults.xcresult | xcbeautify

# Not part of `check`: it rebuilds and re-indexes, making it the slowest step, and a
# starter's shared surface is unused by design. Valuable once real features exist.
deadcode: ## Fail on unused declarations (run on demand)
	@periphery scan --config .periphery.yml

check: doctor format-check lint build test ## The gate

clean: ## Remove build artefacts
	@rm -rf TestResults.xcresult DerivedData
