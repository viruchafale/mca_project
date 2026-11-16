PYTHON ?= python3
.PHONY: test wave lint
test:
	$(PYTHON) tools/run_tests.py
wave:
	$(PYTHON) tools/run_tests.py --wave
lint:
	$(PYTHON) tools/run_tests.py --lint-only
