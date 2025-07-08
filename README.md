# Behave-Playwright Framework

Zero-dependency containerized test automation framework using Behave + Playwright + BehaveX.

## The Problem

Traditional testing frameworks pollute your project with language-specific dependencies. Python projects get more Python deps, non-Python projects get Python deps they don't want.

## The Solution

**Containerized testing framework** - all dependencies live in Docker, your project stays clean.

## Quick Start

```bash
# Bootstrap new project
./bootstrap-container.sh my-project /path/to/directory

# Run tests
cd /path/to/directory/my-project
./test

# View reports
./test --report
```

## What You Get

Your project structure:
```
my-project/
├── src/                    # Your actual code (any language)
├── tests/
│   ├── features/          # BDD scenarios (.feature files)
│   ├── steps/             # Step definitions (.py files)
│   ├── test.config        # Simple configuration
│   └── environment.py     # Test setup
├── reports/               # Generated reports
└── test*                  # Single executable
```

## Commands

```bash
./test                     # Run all tests
./test --headless          # Run without browser UI
./test --tag @smoke        # Run specific tests
./test --report            # Open Allure reports
./test --clean             # Clean up
./test --help              # Show help
```

## Configuration

Edit `tests/test.config`:
```ini
[general]
url = https://your-site.com
browser = Chrome
tags = @smoke
headless = false
```

## Benefits

✅ **Zero host dependencies** (only Docker)  
✅ **Any language project** can use it  
✅ **No version conflicts**  
✅ **Single command setup**  
✅ **Feels like native binary**  
✅ **CI/CD friendly**  

## Requirements

- Docker (that's it)

## Traditional vs Containerized

### Traditional Approach
```bash
# Pollutes project with Python deps
pip install -r requirements.txt
python3 -m venv venv
source venv/bin/activate
playwright install
python3 runner.py
```

### Containerized Approach
```bash
# Clean, simple, no dependencies
./test
```

## Legacy Bootstrap (Non-Containerized)

If you prefer the traditional approach:
```bash
./bootstrap.sh my-project /path/to/directory
cd /path/to/directory/my-project
make setup
make test
```

## Architecture

- **Framework**: Python + Behave + Playwright + BehaveX (in container)
- **Interface**: Single shell script (on host)
- **Tests**: Features + Steps (on host, mounted to container)
- **Reports**: Generated to host filesystem
- **Config**: Simple INI file

Done. Simple. Clean.