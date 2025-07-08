# Behave-Playwright Bootstrap

Bootstrap a new test automation project with Behave + Playwright + BehaveX.

## Quick Start

```bash
# Bootstrap new project
./bootstrap.sh my-project-name /path/to/new/directory

# Or in current directory
./bootstrap.sh my-project-name

# Setup and run
cd my-project-name
make setup
make test
```

## What You Get

- **Behave** - BDD test framework
- **Playwright** - Browser automation
- **BehaveX** - Parallel execution
- **Allure** - Test reporting
- **Sample tests** - Working examples
- **Makefile** - Simple commands

## Commands

- `make setup` - Install everything
- `make test` - Run tests
- `make test-headless` - Run headless
- `make report` - View Allure reports
- `make clean` - Clean up
- `make help` - Show help

## Structure

```
my-project/
├── tests/
│   ├── features/     # BDD scenarios
│   ├── steps/        # Step definitions
│   └── pages/        # Page objects
├── resources/
│   └── details.ini   # Configuration
├── Makefile          # Commands
└── runner.py         # Test runner
```

## Configuration

Edit `resources/details.ini`:
- `url = https://your-site.com` - Target URL
- `browser = Chrome` - Browser choice
- `tags = @smoke` - Which tests to run
- `headless = true` - Run without UI

Done.