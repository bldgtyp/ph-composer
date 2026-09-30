.PHONY: ci syntax lint lint-ruby lint-js lint-python test fixtures fixtures-check coverage hostkit-test python-check \
        panel-manifest panel-manifest-check ui-preview ui-checks rbz rbz-check install clean bridge-install \
        bridge-uninstall runtime-check runtime-pin-check runtime-manifest runtime-browser-check phase-one-proof

# `.ruby-version` pins 3.2.2, the Ruby the current proving host embeds. rbenv resolves it when it
# is installed; without rbenv this falls back to whatever `ruby` is on PATH, and the suite's own
# version guard says so if that is outside the supported span.
# `:=`, not `?=`: a recursive assignment re-runs `rbenv which` on every recipe line naming $(RUBY).
ifeq ($(origin RUBY),undefined)
RUBY := $(shell rbenv which ruby 2>/dev/null || command -v ruby)
endif
export RUBY
RB_FILES := $(shell find src tests tools -name '*.rb' -type f | sort)
JS_TESTS := $(wildcard tests/*_test.js)
# Rubocop is reached through the bundler that belongs to $(RUBY), never whatever `bundle` is first
# on PATH: on macOS that is the system Ruby's, which cannot read this lock.
BUNDLE := $(dir $(RUBY))bundle
SKETCHUP_VERSION ?= 2026

# Every target docs/DEVELOPMENT.md claims for the offline loop that exists today.
ci: syntax lint test fixtures-check panel-manifest-check runtime-check runtime-pin-check hostkit-test python-check rbz \
    rbz-check

syntax:
	@for file in $(RB_FILES); do $(RUBY) -c "$$file" >/dev/null || exit 1; done
	@echo "Ruby syntax: $(words $(RB_FILES)) files OK"

# One run reports every language's failures instead of stopping at the first. The JavaScript files
# are found by glob, so a new `tests/*_test.js` needs no Makefile line.
test:
	@$(RUBY) -Itests tests/all_tests.rb; ruby_status=$$?; \
	 if [ -n "$(JS_TESTS)" ]; then node --test $(JS_TESTS); js_status=$$?; \
	 else echo "JavaScript suite: no tests found"; js_status=1; fi; \
	 uv run pytest; py_status=$$?; \
	 exit $$((ruby_status | js_status | py_status))

# Three rule sets, one target. Rubocop and eslint are developer tools the extension does not
# need, so each prints a named skip when absent and `make test` keeps working on a checkout with
# neither. CI installs both, so nothing skips there; a local skip is not gate evidence.
lint: lint-ruby lint-js lint-python

lint-ruby:
	@if [ -x "$(BUNDLE)" ] && $(BUNDLE) check >/dev/null 2>&1; then \
	  $(BUNDLE) exec rubocop; \
	else \
	  echo "lint-ruby: skipped, rubocop is not installed (run 'bundle install')"; \
	fi

lint-js:
	@if command -v pnpm >/dev/null 2>&1 && [ -d node_modules ]; then \
	  pnpm exec eslint .; \
	else \
	  echo "lint-js: skipped, eslint is not installed (run 'pnpm install')"; \
	fi

# No skip: `test` and `python-check` already require `uv`.
lint-python:
	@uv run ruff check tools tests/python src/ph_composer/python
	@uv run ruff format --check tools tests/python src/ph_composer/python

# The owning tests, one per golden: exactly one test may write each file (docs/DEVELOPMENT.md
# "Fixtures and coverage"). A new golden adds its owner here and its path below.
FIXTURE_OWNERS := phase_one_export api_reference
FIXTURE_PATHS := tests/fixtures tests/python/fixtures docs/API_REFERENCE.md

fixtures:
	@if [ -z "$(strip $(FIXTURE_OWNERS))" ]; then echo "fixtures: no generated goldens yet"; else \
	  PHC_WRITE_FIXTURES=1 $(RUBY) -Itests $(addprefix -r,$(addsuffix _test,$(FIXTURE_OWNERS))) -e ""; fi

# Regenerate, then fail if that changed anything the branch has not committed.
fixtures-check:
	@$(MAKE) --no-print-directory fixtures >/dev/null
	@if [ -n "$$(git status --porcelain -- $(FIXTURE_PATHS))" ]; then \
	  echo "fixtures are stale; run 'make fixtures' and commit the result:"; \
	  git status --short -- $(FIXTURE_PATHS); \
	  exit 1; \
	fi
	@echo "Fixtures up to date"

# Separate from ci: run it before a phase gate. Thresholds ratchet upward only. Python coverage
# measures the shipped translation package.
RUBY_COVERAGE_MIN ?= 93
JS_COVERAGE_MIN ?= 94
PYTHON_COVERAGE_MIN ?= 92

coverage:
	@$(RUBY) tools/coverage_ruby.rb $(RUBY_COVERAGE_MIN)
	@node tools/coverage_js.js $(JS_COVERAGE_MIN)
	@uv run pytest -q --cov=src/ph_composer/python --cov-report=term --cov-fail-under=$(PYTHON_COVERAGE_MIN) tests/python

# Development-only P1-C proof. Inline dependency pins isolate the accepted Honeybee stack from
# the zero-wheel shipping composition until P1-E vendors the selected runtime payload.
phase-one-proof:
	@uv run tools/examples/phase_one/translate_two_zones.py

# The panel pages' <script> lists, generated from the PhComposerUI.define declarations
# (tools/panel_manifest.js). Rewrite after adding, renaming or re-declaring a panel module.
panel-manifest:
	@node tools/panel_manifest.js --write

panel-manifest-check:
	@node tools/panel_manifest.js

# The panel preview (tools/ui-preview/.index.md): the real panel, a stand-in host and the synthetic editor.
# Serves the repository root so the page can load the panel files; ctrl-c stops it.
UI_PREVIEW_PORT ?= 8765

ui-preview:
	@echo "preview on http://127.0.0.1:$(UI_PREVIEW_PORT)/tools/ui-preview/; ctrl-c stops it"
	@uv run --no-project python -m http.server $(UI_PREVIEW_PORT) --bind 127.0.0.1

# The browser checks in tools/ui-preview/ against the preview, on a loopback server this target starts and
# stops. Playwright is never a project dependency: it resolves from NODE_PATH (a scratch `pnpm add
# playwright` outside the repository) and drives the installed Chrome. Without it the target skips by name.
# Not part of `ci`: it launches a browser. A browser pass is not host acceptance.
ui-checks:
	@if ! node -e "require.resolve('playwright')" >/dev/null 2>&1; then \
	  echo "ui-checks: skipped, Playwright is not resolvable (see tools/ui-preview/.index.md)"; exit 0; \
	fi; \
	if curl -s -o /dev/null "http://127.0.0.1:$(UI_PREVIEW_PORT)/"; then \
	  echo "ui-checks: port $(UI_PREVIEW_PORT) is already serving; stop that server or set UI_PREVIEW_PORT"; exit 1; \
	fi; \
	uv run --no-project python -m http.server $(UI_PREVIEW_PORT) --bind 127.0.0.1 >/dev/null 2>&1 & server=$$!; \
	trap 'kill $$server 2>/dev/null; wait $$server 2>/dev/null' EXIT; \
	for attempt in $$(seq 50); do curl -s -o /dev/null "http://127.0.0.1:$(UI_PREVIEW_PORT)/" && break; sleep 0.2; done; \
	status=0; \
	for script in $(sort $(wildcard tools/ui-preview/*.cjs)); do \
	  UI_PREVIEW_PORT=$(UI_PREVIEW_PORT) node "$$script" || status=1; \
	done; \
	exit $$status

# The development host bridge and helpers: Ruby tests against the stub, then the Python client.
hostkit-test:
	@$(RUBY) -Itests -Itools/hostkit/tests tools/hostkit/tests/all.rb
	@uv run pytest -q tools/hostkit/tests

python-check:
	@uv run mypy --config-file pyproject.toml

# The runtime manifest (src/ph_composer/vendor/manifest.json) pins every asset the loopback server may
# serve. Regenerate it after editing anything under html/ or python/: panel-manifest first, since
# the runtime manifest hashes the pages it writes, then this, then rbz.
runtime-manifest:
	@uv run tools/runtime/vendor.py --refresh-manifest

# Offline: the tree, the Pyodide pin, the gates and the installed-size budget agree with the manifest.
runtime-check:
	@uv run tools/runtime/vendor.py --check

runtime-pin-check:
	@uv run tools/runtime/vendor.py --pins-check

# The shipped runtime page, booted in Chromium 88 (tools/runtime/browser_check.py). Not part of `ci`: it
# launches a browser, and a browser pass is not host evidence.
runtime-browser-check:
	@uv run tools/runtime/browser_check.py

rbz:
	@uv run tools/rbz/build.py

rbz-check:
	@uv run tools/rbz/build.py --check

install:
	@uv run tools/rbz/build.py --install --sketchup-version "$(SKETCHUP_VERSION)"

clean:
	@uv run tools/rbz/build.py --clean

PLUGINS_DIR := $(HOME)/Library/Application Support/SketchUp $(SKETCHUP_VERSION)/SketchUp/Plugins

# Development host bridge (tools/hostkit/host_bridge.rb): never part of the RBZ.
bridge-install:
	@cp tools/hostkit/host_bridge.rb "$(PLUGINS_DIR)/ph_composer_host_bridge.rb"
	@echo "host bridge installed into $(PLUGINS_DIR)"

bridge-uninstall:
	@rm -f "$(PLUGINS_DIR)/ph_composer_host_bridge.rb" "$(PLUGINS_DIR)/../ph_composer_host_bridge.json"
	@echo "host bridge removed"
