import sys
import os
import subprocess
import configparser
import logging
from pathlib import Path

# Add tests directory to Python path for user step definitions
sys.path.insert(0, '/tests')

def setup_logging():
    """Setup logging configuration"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)

def read_config():
    """Read test configuration"""
    config = configparser.ConfigParser()
    config_path = '/tests/test.config'

    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Configuration file not found: {config_path}")

    config.read(config_path)
    return config

def prepare_directories():
    """Create necessary output directories"""
    directories = [
        '/reports/allure_report',
        '/reports/html',
        '/reports/screenshots',
        '/reports/pretty',
        '/reports/json',
        '/reports/rerun',
        '/reports/allure_json'
    ]

    for directory in directories:
        os.makedirs(directory, exist_ok=True)

def run_tests(config, logger):
    """Execute tests using behavex"""
    tags = config.get('general', 'tags', fallback='@smoke')

    # Build behavex command
    cmd = [
        'behavex',
        '/tests/features',
        '--parallel-processes', '2',
        '--parallel-delay', '1000',
        '--parallel-scheme', 'scenario',
        '--show-progress-bar',
        f'-t={tags}'
    ]

    logger.info(f"Executing command: {' '.join(cmd)}")

    # Set up environment - only tests directory needed
    env = os.environ.copy()
    env['PYTHONPATH'] = '/tests'

    # Execute tests
    try:
        result = subprocess.run(
            cmd,
            env=env,
            cwd='/tests',
            check=False  # Don't raise exception on non-zero exit
        )

        logger.info(f"Test execution completed with exit code: {result.returncode}")
        return result.returncode

    except Exception as e:
        logger.error(f"Error executing tests: {e}")
        return 1

def generate_allure_report(logger):
    """Generate Allure report if results exist"""
    allure_results = '/reports/allure_json'
    allure_output = '/reports/allure_report'

    if os.path.exists(allure_results) and os.listdir(allure_results):
        logger.info("Generating Allure report...")

        try:
            subprocess.run([
                'allure', 'generate',
                allure_results,
                '-o', allure_output,
                '--clean'
            ], check=True)

            logger.info(f"Allure report generated: {allure_output}")

        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to generate Allure report: {e}")
        except Exception as e:
            logger.error(f"Unexpected error generating Allure report: {e}")
    else:
        logger.warning("No Allure results found, skipping report generation")

def main():
    """Main execution function"""
    logger = setup_logging()

    try:
        logger.info("Starting Behave-Playwright test execution")

        # Read configuration
        config = read_config()
        logger.info("Configuration loaded successfully")

        # Prepare directories
        prepare_directories()
        logger.info("Output directories prepared")

        # Run tests
        exit_code = run_tests(config, logger)

        # Generate reports
        generate_allure_report(logger)

        logger.info("Test execution completed")

        # Exit with the same code as the test execution
        sys.exit(exit_code)

    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
