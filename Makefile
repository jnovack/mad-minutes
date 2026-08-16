.DEFAULT_GOAL := serve

PYTHON ?= python3
HOST ?= 127.0.0.1
PORT ?= 8000
URL := http://$(HOST):$(PORT)/

.PHONY: serve
serve:
	@echo "Serving Mad Minutes at $(URL)"
	@echo "Press Ctrl-C to stop the server."
	@if command -v open >/dev/null 2>&1; then \
		(sleep 1; open "$(URL)" >/dev/null 2>&1) & \
	elif command -v xdg-open >/dev/null 2>&1; then \
		(sleep 1; xdg-open "$(URL)" >/dev/null 2>&1) & \
	else \
		echo "Open $(URL) in your browser."; \
	fi; \
	$(PYTHON) -m http.server "$(PORT)" --bind "$(HOST)"
