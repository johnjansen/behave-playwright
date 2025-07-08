#!/bin/bash
set -e

# Entrypoint script for Behave-Playwright Docker container
# Handles test execution and report serving

# Validate required test files exist
if [ ! -f /tests/test.config ]; then
    echo "ERROR: test.config not found. Please ensure your test directory is properly mounted."
    exit 1
fi

if [ ! -d /tests/features ]; then
    echo "ERROR: features directory not found. Please ensure your test directory is properly mounted."
    exit 1
fi

# Parse command line arguments
HEADLESS=""
TAGS=""
REPORT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --headless)
            HEADLESS="true"
            shift
            ;;
        --tag)
            TAGS="$2"
            shift 2
            ;;
        --report)
            REPORT=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Update config based on arguments
if [ "$HEADLESS" = "true" ]; then
    sed -i 's/headless = false/headless = true/' /tests/test.config
fi

if [ -n "$TAGS" ]; then
    sed -i "s/tags = @smoke/tags = $TAGS/" /tests/test.config
fi

# Create necessary directories
mkdir -p /reports/{allure_report,html,screenshots,pretty,json,rerun,allure_json}

# Handle report serving or test execution
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
    # Run tests
    export PYTHONPATH=/tests
    cd /framework
    python runner.py
fi
