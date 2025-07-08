#!/bin/bash
set -e

# Behave-Playwright Framework Installer
# This script installs the containerized testing framework

REPO_URL="https://raw.githubusercontent.com/behavex/playwright-framework/main"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed."
        log_info "Please install Docker first:"
        log_info "  macOS: https://docs.docker.com/desktop/mac/install/"
        log_info "  Linux: https://docs.docker.com/engine/install/"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker."
        exit 1
    fi

    log_success "Docker is installed and running"
}

# Create install directory
create_install_dir() {
    mkdir -p "$INSTALL_DIR"
    log_success "Created install directory: $INSTALL_DIR"
}

# Download and install the test script
install_script() {
    log_info "Installing test script..."

    # Create the test script locally (since we're bootstrapping)
    cat > "$INSTALL_DIR/$SCRIPT_NAME" << 'EOF'
#!/bin/bash
set -e

# Container launcher script for Behave-Playwright framework
# This script provides a native binary feel while running tests in Docker

SCRIPT_DIR="$(pwd)"
IMAGE_NAME="behavex/playwright-framework"
CONTAINER_NAME="behavex-tests-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker to use this testing framework."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker."
        exit 1
    fi
}

# Initialize project structure
init_project() {
    log_info "Initializing test project structure..."

    # Create directories
    mkdir -p tests/features
    mkdir -p tests/steps
    mkdir -p tests/pages
    mkdir -p reports

    # Create sample feature if none exists
    if [ ! -f tests/features/sample.feature ]; then
        cat > tests/features/sample.feature << 'FEATURE_EOF'
Feature: Sample Test
    As a test automation engineer
    I want to verify the framework works
    So that I can write effective tests

    @smoke
    Scenario: Framework smoke test
        Given I navigate to the homepage
        When I verify the page loads
        Then I should see the page title
FEATURE_EOF
    fi

    # Create sample steps if none exists
    if [ ! -f tests/steps/sample_steps.py ]; then
        cat > tests/steps/sample_steps.py << 'STEPS_EOF'
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
STEPS_EOF
    fi

    # Create __init__.py files
    touch tests/__init__.py
    touch tests/steps/__init__.py
    touch tests/pages/__init__.py

    # Create config if it doesn't exist
    if [ ! -f tests/test.config ]; then
        cat > tests/test.config << 'CONFIG_EOF'
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
CONFIG_EOF
    fi

    log_success "Project structure initialized"
}

# Build Docker image if it doesn't exist
build_image() {
    if ! docker image inspect $IMAGE_NAME &> /dev/null; then
        log_info "Downloading and building Docker image for the first time..."

        # Create temporary directory for Docker build
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"

        # Download Dockerfile and framework files
        curl -fsSL https://raw.githubusercontent.com/your-org/behavex-playwright/main/Dockerfile > Dockerfile
        curl -fsSL https://raw.githubusercontent.com/your-org/behavex-playwright/main/requirements.txt > requirements.txt

        # For now, create a simple Dockerfile inline
        cat > Dockerfile << 'DOCKER_EOF'
FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install Allure
RUN wget -O - https://repo.maven.apache.org/maven2/io/qameta/allure/allure-commandline/2.24.0/allure-commandline-2.24.0.tgz | tar -xzC /opt/ \
    && ln -s /opt/allure-2.24.0/bin/allure /usr/local/bin/allure

# Set working directory
WORKDIR /framework

# Install Python dependencies
RUN pip install --no-cache-dir \
    behave~=1.2.6 \
    allure-behave \
    behavex \
    allure-python-commons~=2.13.5 \
    faker \
    pycommons-lang \
    playwright \
    requests \
    configparser \
    setuptools

# Install Playwright browsers
RUN playwright install --with-deps

# Create minimal framework structure
RUN mkdir -p helpers/constants utils/reporting

# Create framework files
RUN cat > runner.py << 'RUNNER_EOF'
import sys
import os
sys.path.insert(0, '/tests')
import subprocess
import configparser

def main():
    # Simple runner that executes behavex
    config = configparser.ConfigParser()
    config.read('/tests/test.config')

    tags = config.get('general', 'tags', fallback='@smoke')

    cmd = [
        'behavex', '/tests/features',
        '--parallel-processes', '2',
        '--parallel-delay', '1000',
        '--parallel-scheme', 'scenario',
        '--show-progress-bar',
        f'-t={tags}'
    ]

    # Set environment
    env = os.environ.copy()
    env['PYTHONPATH'] = '/framework:/tests'

    # Run tests
    result = subprocess.run(cmd, env=env)

    # Generate allure report
    if os.path.exists('/reports/allure_json'):
        subprocess.run(['allure', 'generate', '/reports/allure_json', '-o', '/reports/allure_report', '--clean'])

    sys.exit(result.returncode)

if __name__ == '__main__':
    main()
RUNNER_EOF

RUN cat > behave.ini << 'BEHAVE_EOF'
[behave]
format = pretty
 json.pretty
 rerun
 allure_behave.formatter:AllureFormatter

outfiles = /reports/pretty/pretty.txt
 /reports/json/report.json
 /reports/rerun/rerun.txt
 /reports/allure_json

stderr_capture = True
stdout_capture = True
log_capture = True
logging_level = INFO

verbose = True
paths = /tests/features/
color = True
dry_run = False
show_timings = True
show_skipped = false
BEHAVE_EOF

# Create entrypoint
RUN cat > /entrypoint.sh << 'ENTRY_EOF'
#!/bin/bash
set -e

# Create necessary directories
mkdir -p /reports/{allure_report,html,screenshots,pretty,json,rerun,allure_json}

# Parse arguments
REPORT=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --report)
            REPORT=true
            shift
            ;;
        --headless)
            sed -i 's/headless = false/headless = true/' /tests/test.config
            shift
            ;;
        --tag)
            sed -i "s/tags = @smoke/tags = $2/" /tests/test.config
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [ "$REPORT" = "true" ]; then
    if [ -d "/reports/allure_report" ] && [ "$(ls -A /reports/allure_report)" ]; then
        echo "Starting Allure report server..."
        cd /reports
        allure serve allure_report
    else
        echo "No reports found. Run tests first."
        exit 1
    fi
else
    cd /framework
    python runner.py
fi
ENTRY_EOF

RUN chmod +x /entrypoint.sh

VOLUME ["/tests", "/reports"]
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
DOCKER_EOF

        docker build -t $IMAGE_NAME .
        cd - > /dev/null
        rm -rf "$TEMP_DIR"

        log_success "Docker image built successfully"
    fi
}

# Show help
show_help() {
    echo "Behave-Playwright Test Framework"
    echo ""
    echo "Usage: test [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --headless          Run tests in headless mode"
    echo "  --tag TAG           Run tests with specific tag (e.g., @smoke)"
    echo "  --report            Open Allure report server"
    echo "  --init              Initialize project structure"
    echo "  --build             Force rebuild Docker image"
    echo "  --clean             Clean up reports and containers"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  test                Run all tests"
    echo "  test --headless     Run tests without browser UI"
    echo "  test --tag @smoke   Run only smoke tests"
    echo "  test --report       Open test reports"
    echo "  test --init         Set up new test project"
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
    # Parse arguments
    INIT=false
    BUILD=false
    CLEAN=false
    DOCKER_ARGS=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --init)
                INIT=true
                shift
                ;;
            --build)
                BUILD=true
                shift
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                DOCKER_ARGS="$DOCKER_ARGS $1"
                shift
                ;;
        esac
    done

    # Handle special commands
    if [ "$INIT" = true ]; then
        init_project
        exit 0
    fi

    if [ "$CLEAN" = true ]; then
        cleanup
        exit 0
    fi

    # Check prerequisites
    check_docker

    # Force build if requested
    if [ "$BUILD" = true ]; then
        docker rmi $IMAGE_NAME 2>/dev/null || true
    fi

    # Build image if needed
    build_image

    # Validate project structure
    if [ ! -d "tests" ]; then
        log_warning "No tests directory found. Run 'test --init' to set up project structure."
        exit 1
    fi

    # Run container
    log_info "Starting test execution..."

    # Set up port mapping for report server
    PORT_MAPPING=""
    if [[ "$DOCKER_ARGS" == *"--report"* ]]; then
        PORT_MAPPING="-p 8080:8080"
    fi

    # Run the container
    docker run --rm \
        --name $CONTAINER_NAME \
        $PORT_MAPPING \
        -v "$SCRIPT_DIR/tests:/tests" \
        -v "$SCRIPT_DIR/reports:/reports" \
        $IMAGE_NAME \
        $DOCKER_ARGS

    # Show results
    if [[ "$DOCKER_ARGS" != *"--report"* ]]; then
        log_success "Test execution completed"
        log_info "View reports with: test --report"
        log_info "Reports saved to: $SCRIPT_DIR/reports/"
    fi
}

# Execute main function
main "$@"
EOF

    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    log_success "Test script installed to $INSTALL_DIR/$SCRIPT_NAME"
}

# Add to PATH
update_path() {
    # Check if already in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        log_success "Install directory already in PATH"
        return
    fi

    # Add to shell profile
    SHELL_PROFILE=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_PROFILE="$HOME/.bashrc"
    fi

    if [[ -n "$SHELL_PROFILE" ]]; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_PROFILE"
        log_success "Added $INSTALL_DIR to PATH in $SHELL_PROFILE"
        log_warning "Please restart your shell or run: source $SHELL_PROFILE"
    else
        log_warning "Could not determine shell profile. Please manually add $INSTALL_DIR to your PATH"
    fi
}

# Main installation process
main() {
    echo "🚀 Installing Behave-Playwright Framework..."
    echo ""

    check_docker
    create_install_dir
    install_script
    update_path

    echo ""
    log_success "Installation completed successfully!"
    echo ""
    echo "Quick start:"
    echo "  1. cd /path/to/your/project"
    echo "  2. test --init"
    echo "  3. test"
    echo ""
    echo "Commands:"
    echo "  test --init     Initialize new test project"
    echo "  test            Run tests"
    echo "  test --headless Run tests without browser UI"
    echo "  test --report   View test reports"
    echo "  test --help     Show all options"
    echo ""
    log_info "Framework documentation: https://github.com/behavex/playwright-framework"
}

# Execute main function
main "$@"
