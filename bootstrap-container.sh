#!/bin/bash
set -e

# Containerized Bootstrap Script for Behave-Playwright Framework
# Creates only host-side test files - container is pure infrastructure

PROJECT_NAME=${1:-"my-tests"}
TARGET_DIR=${2:-$(pwd)}

echo "🚀 Bootstrapping containerized Behave-Playwright framework..."
echo "Project: $PROJECT_NAME"
echo "Target: $TARGET_DIR"

# Create project structure
mkdir -p "$TARGET_DIR/$PROJECT_NAME"
cd "$TARGET_DIR/$PROJECT_NAME"

# Create directory structure
mkdir -p tests/{features,steps,pages}
mkdir -p reports

# Create test launcher script
cat > test << 'EOF'
#!/bin/bash
set -e

# Container launcher script for Behave-Playwright framework
SCRIPT_DIR="$(pwd)"
IMAGE_NAME="behavex/playwright-framework"
CONTAINER_NAME="behavex-tests-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker not installed. Please install Docker first."
        exit 1
    fi
    if ! docker info &> /dev/null; then
        log_error "Docker not running. Please start Docker."
        exit 1
    fi
}

# Build image if needed
build_image() {
    if ! docker image inspect $IMAGE_NAME &> /dev/null; then
        log_error "Docker image $IMAGE_NAME not found."
        log_info "Please build the image first or pull from registry."
        exit 1
    fi
}

# Show help
show_help() {
    echo "Behave-Playwright Test Framework"
    echo ""
    echo "Usage: ./test [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --headless    Run tests in headless mode"
    echo "  --tag TAG     Run tests with specific tag"
    echo "  --report      Open Allure report server"
    echo "  --clean       Clean up reports"
    echo "  --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  ./test              Run all tests"
    echo "  ./test --headless   Run without browser UI"
    echo "  ./test --tag @smoke Run smoke tests only"
    echo "  ./test --report     Open test reports"
    echo ""
}

# Clean up
cleanup() {
    log_info "Cleaning up..."
    docker ps -a --filter "name=$CONTAINER_NAME" -q | xargs -r docker rm -f
    if [ -d "reports" ]; then
        rm -rf reports/*
        log_success "Reports cleaned"
    fi
}

# Main execution
main() {
    CLEAN=false
    DOCKER_ARGS=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean) CLEAN=true; shift ;;
            --help) show_help; exit 0 ;;
            *) DOCKER_ARGS="$DOCKER_ARGS $1"; shift ;;
        esac
    done

    if [ "$CLEAN" = true ]; then
        cleanup
        exit 0
    fi

    check_docker
    build_image

    if [ ! -d "tests" ]; then
        log_error "No tests directory found. Check project structure."
        exit 1
    fi

    log_info "Starting test execution..."

    PORT_MAPPING=""
    if [[ "$DOCKER_ARGS" == *"--report"* ]]; then
        PORT_MAPPING="-p 8080:8080"
    fi

    docker run --rm \
        --name $CONTAINER_NAME \
        $PORT_MAPPING \
        -v "$SCRIPT_DIR/tests:/tests" \
        -v "$SCRIPT_DIR/reports:/reports" \
        $IMAGE_NAME \
        $DOCKER_ARGS

    if [[ "$DOCKER_ARGS" != *"--report"* ]]; then
        log_success "Test execution completed"
        log_info "View reports with: ./test --report"
    fi
}

main "$@"
EOF

chmod +x test

# Create test configuration
cat > tests/test.config << 'EOF'
[general]
delete_old_reports = true
start_docker_compose = false
headless = false
allow_tracing = true
tags = @smoke
browser = Chrome
url = https://httpbin.org

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

# Create environment setup
cat > tests/environment.py << 'EOF'
import configparser
from playwright.sync_api import sync_playwright

def before_all(context):
    context.details = configparser.ConfigParser()
    context.details.read('/tests/test.config')

def before_scenario(context, scenario):
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
    context.base_url = context.details.get("general", "url", fallback="https://httpbin.org")

def after_scenario(context, scenario):
    if hasattr(context, 'page'):
        context.page.close()
    if hasattr(context, 'browser'):
        context.browser.close()
    if hasattr(context, 'playwright'):
        context.playwright.stop()
EOF

# Create init files
touch tests/__init__.py tests/steps/__init__.py tests/pages/__init__.py

# Create README
cat > README.md << EOF
# $PROJECT_NAME

Containerized Behave-Playwright test automation framework.

## Quick Start

\`\`\`bash
# Run tests
./test

# Run headless
./test --headless

# Run specific tag
./test --tag @smoke

# View reports
./test --report

# Clean up
./test --clean
\`\`\`

## Configuration

Edit \`tests/test.config\`:
- \`url = https://your-site.com\` - Target URL
- \`browser = Chrome\` - Browser choice
- \`tags = @smoke\` - Which tests to run
- \`headless = true\` - Run without UI

## Structure

- \`tests/features/\` - BDD scenarios
- \`tests/steps/\` - Step definitions
- \`tests/test.config\` - Configuration
- \`reports/\` - Generated reports
- \`./test\` - Test runner

## Requirements

- Docker (only dependency)
- Container image: \`behavex/playwright-framework\`

No Python, no dependencies, just Docker.
EOF

echo "✅ Containerized framework bootstrapped successfully!"
echo ""
echo "Next steps:"
echo "1. cd $TARGET_DIR/$PROJECT_NAME"
echo "2. Build the container image: make build-container"
echo "3. ./test"
echo "4. ./test --report"
echo ""
echo "Edit tests/test.config to configure your tests."
echo "Only Docker is required - no Python dependencies!"
