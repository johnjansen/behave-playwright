#!/bin/bash
set -e

PROJECT_NAME=${1:-"my-tests"}
TARGET_DIR=${2:-$(pwd)}

echo "🚀 Bootstrapping Behave-Playwright framework..."
echo "Project: $PROJECT_NAME"
echo "Target: $TARGET_DIR"

# Create project structure
mkdir -p "$TARGET_DIR/$PROJECT_NAME"
cd "$TARGET_DIR/$PROJECT_NAME"

# Create directory structure
mkdir -p tests/{features,steps,pages}
mkdir -p utils/reporting
mkdir -p helpers/constants
mkdir -p resources
mkdir -p reports

# Create requirements.txt
cat > requirements.txt << 'EOF'
behave~=1.2.6
allure-behave
behavex
allure-python-commons~=2.13.5
faker
pycommons-lang
playwright
requests
configparser
setuptools
EOF

# Create Makefile
cat > Makefile << 'EOF'
.PHONY: setup install test test-headless report clean help

help:
	@echo "Available targets:"
	@echo "  setup       - Install dependencies and setup environment"
	@echo "  install     - Install Python dependencies only"
	@echo "  test        - Run tests"
	@echo "  test-headless - Run tests in headless mode"
	@echo "  report      - Open Allure report"
	@echo "  clean       - Clean up reports and temp files"

setup:
	brew install python@3.12 uv allure
	uv venv --python python3.12
	. .venv/bin/activate && uv pip install -r requirements.txt
	. .venv/bin/activate && playwright install
	sed -i '' 's/start_docker_compose = true/start_docker_compose = false/' resources/details.ini
	mkdir -p reports/allure_report

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
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
EOF

# Create behave.ini
cat > behave.ini << 'EOF'
[behave]
format = pretty
 json.pretty
 rerun
 allure_behave.formatter:AllureFormatter

outfiles = reports/pretty/pretty.txt
 reports/json/report.json
 reports/rerun/rerun.txt
 reports/allure_json

stderr_capture = True
stdout_capture = True
log_capture = True
logging_level = INFO
logging_format = LOG.%(levelname)-8s  %(asctime)s  %(name)-10s: %(message)s

verbose = True
paths = tests/features/
color = True
dry_run = False
show_timings = True
show_skipped = false
EOF

# Create conf_behavex.cfg
cat > conf_behavex.cfg << 'EOF'
[output]
path = "reports/html"
EOF

# Create resources/details.ini
cat > resources/details.ini << EOF
[general]
delete_old_reports = true
start_docker_compose = false
password_for_sshpass = password
headless = false
allow_tracing = true
tags = @smoke
selenium_host_ip = 127.0.0.1
browser = Chrome
url = https://example.com

[elk]
add_in_elk = false
elk_url = http://localhost:9200

[email]
send_report_on_email = false
token =
sender_email =
receiver_email =

[test_user]
username = testuser
password = testpass
EOF

# Create runner.py
cat > runner.py << 'EOF'
import configparser
import logging
from pathlib import Path
from pycommons.lang.stringutils import StringUtils
from utils.helper_utils import prepare_dirs, execute_command_using_popen
from utils.reporting.generate_report import generate_allure_report
from helpers.constants.framework_constants import FrameworkConstants as Fc

def logs():
    logger = logging.getLogger()
    if not logger.hasHandlers():
        logger.handlers.clear()
        logging.basicConfig(level=logging.INFO, format="%(message)s")
    return logger

def start_tests(log):
    details_ini = configparser.ConfigParser()
    details_ini.read(Fc.details_file)
    tags = details_ini.get("general", "tags")
    prepare_dirs()

    command = (
        f"behavex {Fc.features} -c {Fc.conf_behavex} "
        f"--parallel-processes 2 --parallel-delay 1000 "
        f"--parallel-scheme scenario --show-progress-bar -t={tags}"
    )
    print(command)
    process = execute_command_using_popen(command)

    try:
        while True:
            output = process.stdout.readline()
            if output == StringUtils.EMPTY and process.poll() is not None:
                break
            if output:
                log.info(output.strip())
    except KeyboardInterrupt:
        log.error("Process terminated by user.")
        process.terminate()
        raise
    finally:
        generate_allure_report(log)

def main():
    log = logs()
    try:
        start_tests(log)
    except Exception as e:
        log.error(f"An unexpected error occurred: {e}")
        raise

if __name__ == "__main__":
    main()
EOF

# Create framework constants
cat > helpers/constants/framework_constants.py << 'EOF'
import os
from pathlib import Path

class FrameworkConstants:
    base_dir = Path(__file__).parent.parent.parent
    details_file = base_dir / "resources" / "details.ini"
    features = base_dir / "tests" / "features"
    conf_behavex = base_dir / "conf_behavex.cfg"
    allure_report = base_dir / "reports" / "allure_report"
    html_report = base_dir / "reports" / "html"
EOF

# Create helper utils
cat > utils/helper_utils.py << 'EOF'
import os
import subprocess
import shutil
from pathlib import Path

def prepare_dirs():
    """Create necessary directories"""
    dirs = [
        "reports/allure_report",
        "reports/html",
        "reports/screenshots",
        "reports/pretty",
        "reports/json",
        "reports/rerun",
        "reports/allure_json",
        "logs"
    ]
    for dir_path in dirs:
        os.makedirs(dir_path, exist_ok=True)

def execute_command_using_popen(command):
    """Execute command using subprocess"""
    return subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True
    )

def execute_command_using_run(command):
    """Execute command using subprocess.run"""
    return subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True
    )
EOF

# Create __init__.py files
cat > tests/__init__.py << 'EOF'
EOF

cat > tests/steps/__init__.py << 'EOF'
EOF

cat > tests/pages/__init__.py << 'EOF'
EOF

cat > utils/__init__.py << 'EOF'
EOF

cat > utils/reporting/__init__.py << 'EOF'
EOF

cat > helpers/__init__.py << 'EOF'
EOF

cat > helpers/constants/__init__.py << 'EOF'
EOF

# Create report generator
cat > utils/reporting/generate_report.py << 'EOF'
import subprocess
import os
from pathlib import Path

def generate_allure_report(logger):
    """Generate Allure report"""
    try:
        allure_results = "reports/allure_json"
        allure_report = "reports/allure_report"

        if os.path.exists(allure_results):
            command = f"allure generate {allure_results} -o {allure_report} --clean"
            result = subprocess.run(command, shell=True, capture_output=True, text=True)

            if result.returncode == 0:
                logger.info(f"Allure report generated: {allure_report}")
            else:
                logger.error(f"Failed to generate Allure report: {result.stderr}")
        else:
            logger.warning(f"Allure results not found: {allure_results}")

    except Exception as e:
        logger.error(f"Error generating Allure report: {e}")
EOF

# Create environment.py
cat > tests/environment.py << 'EOF'
import configparser
from playwright.sync_api import sync_playwright
from helpers.constants.framework_constants import FrameworkConstants as Fc

def before_all(context):
    """Setup before all tests"""
    context.details = configparser.ConfigParser()
    context.details.read(Fc.details_file)

def before_scenario(context, scenario):
    """Setup before each scenario"""
    browser_name = context.details.get("general", "browser", fallback="chrome").lower()
    headless = context.details.getboolean("general", "headless", fallback=False)

    context.playwright = sync_playwright().start()

    if browser_name == "firefox":
        context.browser = context.playwright.firefox.launch(headless=headless)
    elif browser_name == "safari":
        context.browser = context.playwright.webkit.launch(headless=headless)
    else:
        context.browser = context.playwright.chromium.launch(headless=headless)

    context.page = context.browser.new_page()
    context.base_url = context.details.get("general", "url", fallback="https://example.com")

def after_scenario(context, scenario):
    """Cleanup after each scenario"""
    if hasattr(context, 'page'):
        context.page.close()
    if hasattr(context, 'browser'):
        context.browser.close()
    if hasattr(context, 'playwright'):
        context.playwright.stop()
EOF

# Create sample feature
cat > tests/features/sample.feature << 'EOF'
Feature: Sample Test
    As a test automation engineer
    I want to verify the framework works
    So that I can write effective tests

    @smoke
    Scenario: Framework smoke test
        Given I navigate to the homepage
        When I verify the page loads
        Then I should see the page title
EOF

# Create sample steps
cat > tests/steps/sample_steps.py << 'EOF'
from behave import given, when, then
from playwright.sync_api import expect

@given('I navigate to the homepage')
def navigate_to_homepage(context):
    context.page.goto(context.base_url)

@when('I verify the page loads')
def verify_page_loads(context):
    context.page.wait_for_load_state('networkidle')

@then('I should see the page title')
def verify_page_title(context):
    expect(context.page).to_have_title(lambda title: len(title) > 0)
EOF

# Create sample page object
cat > tests/pages/base_page.py << 'EOF'
class BasePage:
    def __init__(self, page):
        self.page = page

    def navigate_to(self, url):
        self.page.goto(url)

    def get_title(self):
        return self.page.title()

    def wait_for_load(self):
        self.page.wait_for_load_state('networkidle')
EOF

# Create README
cat > README.md << EOF
# $PROJECT_NAME

Behave-Playwright test automation framework.

## Setup

\`\`\`bash
make setup
\`\`\`

## Run Tests

\`\`\`bash
make test
\`\`\`

## View Reports

\`\`\`bash
make report
\`\`\`

## Configure

Edit \`resources/details.ini\`:
- \`tags = @your-tag\` - Run specific tests
- \`headless = true\` - Run without browser UI
- \`browser = Chrome\` - Change browser
- \`url = https://your-site.com\` - Target URL

## Commands

- \`make setup\` - Install everything
- \`make test\` - Run tests
- \`make test-headless\` - Run headless
- \`make report\` - View reports
- \`make clean\` - Clean up
- \`make help\` - Show help
EOF

echo "✅ Framework bootstrapped successfully!"
echo ""
echo "Next steps:"
echo "1. cd $TARGET_DIR/$PROJECT_NAME"
echo "2. make setup"
echo "3. make test"
echo ""
echo "Edit resources/details.ini to configure your tests."
