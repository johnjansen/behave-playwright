# Behave-Playwright Test Framework

Python test automation framework using Behave (BDD) + Playwright + BehaveX for parallel execution.

## macOS Setup

```bash
make setup
```

## Run Tests

```bash
make test
```

## View Reports

```bash
make report
```

## Other Commands

```bash
make test-headless    # Run tests without browser UI
make clean           # Clean up reports and temp files
make help            # Show all available commands
```

## Configure

Edit `resources/details.ini`:
- `tags = @your-tag` - Run specific tests
- `headless = true` - Run without browser UI
- `browser = Chrome` - Change browser

Uses `uv` for fast Python environment management.