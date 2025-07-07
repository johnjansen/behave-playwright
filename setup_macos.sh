#!/bin/bash
set -e

echo "🚀 Setting up Behave-Playwright for macOS..."

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Install Python 3.12, uv and Allure
echo "Installing Python 3.12, uv and Allure..."
brew install python@3.12 uv allure

# Create virtual environment and install dependencies
echo "Creating virtual environment and installing dependencies..."
uv venv --python python3.12
source .venv/bin/activate
uv pip install -r requirements.txt

# Install Playwright browsers
echo "Installing Playwright browsers..."
playwright install

# Configure for macOS
echo "Configuring for macOS..."
sed -i '' 's/start_docker_compose = true/start_docker_compose = false/' resources/details.ini

# Create reports directory
mkdir -p reports/allure_report

echo "✅ Setup complete!"
echo ""
echo "To run tests:"
echo "  source .venv/bin/activate"
echo "  python3 runner.py"
echo ""
echo "To view reports:"
echo "  allure serve reports/allure_report"
