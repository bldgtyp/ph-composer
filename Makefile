.PHONY: ci ci-pending syntax lint lint-ruby lint-js lint-python test fixtures fixtures-check coverage hostkit-test python-check \
        rbz rbz-check install clean bridge-install bridge-uninstall

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
ci: syntax lint test fixtures-check hostkit-test python-check rbz rbz-check ci-pending

# The gate is not complete until these land. Printed on every run so a green `make ci` is never
# read as the full Phase 0 gate (planning/refactor/phase-zero/phases/phase-02-bootstrap.md).
ci-pending:
	@echo "Not yet in ci: JavaScript suite and panel manifest (P0-E);"
	@echo "  runtime-pin-check, runtime-check and the RBZ footprint gate (P0-F)."

syntax:
	@for file in $(RB_FILES); do $(RUBY) -c "$$file" >/dev/null || exit 1; done
	@echo "Ruby syntax: $(words $(RB_FILES)) files OK"

# One run reports every language's failures instead of stopping at the first. The JavaScript files
# are found by glob, so a new `tests/*_test.js` needs no Makefile line.
test:
	@$(RUBY) -Itests tests/all_tests.rb; ruby_status=$$?; \
	 if [ -n "$(JS_TESTS)" ]; then node --test $(JS_TESTS); js_status=$$?; \
	 else echo "JavaScript suite: no tests yet (the panel kit arrives in P0-E)"; js_status=0; fi; \
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
	@uv run ruff check tools tests/python
	@uv run ruff format --check tools tests/python

# The owning tests, one per golden: exactly one test may write each file. None exist yet; the
# first golden adds its owner here (docs/DEVELOPMENT.md "Fixtures and coverage").
FIXTURE_OWNERS :=
FIXTURE_PATHS := tests/fixtures tests/python/fixtures

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

# Separate from ci: run it before a phase gate. Thresholds ratchet upward only. JavaScript and
# Python coverage join when their shipped code lands (P0-E, P0-F).
RUBY_COVERAGE_MIN ?= 93

coverage:
	@$(RUBY) tools/coverage_ruby.rb $(RUBY_COVERAGE_MIN)

# The development host bridge and helpers: Ruby tests against the stub, then the Python client.
hostkit-test:
	@$(RUBY) -Itests -Itools/hostkit/tests tools/hostkit/tests/all.rb
	@uv run pytest -q tools/hostkit/tests

python-check:
	@uv run mypy --config-file pyproject.toml

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
