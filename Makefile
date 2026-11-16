PYTHON ?= python3
.PHONY: test wave lint
test:
	$(PYTHON) tools/run_tests.py
wave:
	$(PYTHON) tools/run_tests.py --wave
lint:
	$(PYTHON) tools/run_tests.py --lint-only

.PHONY: synth netlist verify
synth:
	$(PYTHON) tools/run_synthesis.py
netlist: synth
	$(PYTHON) tools/phase4_reference.py
	$(PYTHON) tools/check_netlist.py
verify:
	$(PYTHON) tools/run_tests.py --wave --self-check
	$(PYTHON) tools/run_synthesis.py
	$(PYTHON) tools/check_netlist.py
