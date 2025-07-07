.PHONY: setup install test test-headless report clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  setup       - Install dependencies and setup environment"
	@echo "  install     - Install Python dependencies only"
	@echo "  test        - Run tests"
	@echo "  test-headless - Run tests in headless mode"
	@echo "  report      - Open Allure report"
	@echo "  clean       - Clean up reports and temp files"
	@echo "  help        - Show this help message"

setup:
	./setup_macos.sh

install:
	uv venv --python python3.12
	. .venv/bin/activate && uv pip install -r requirements.txt
	. .venv/bin/activate && playwright install

test:
	. .venv/bin/activate && python3 runner.py

test-headless:
	@sed -i '' 's/headless = false/headless = true/' resources/details.ini
	. .venv/bin/activate && python3 runner.py
	@sed -i '' 's/headless = true/headless = false/' resources/details.ini

report:
	allure serve reports/allure_report

clean:
	rm -rf reports/*
	rm -rf .venv/__pycache__
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} +
