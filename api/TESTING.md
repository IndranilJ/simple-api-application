# Testing Guide

This directory contains unit tests and coverage configuration for the FastAPI application.

## Setup

Install test dependencies:
```bash
pip install -r requirements.txt
```

## Running Tests

### Run all tests
```bash
pytest
```

### Run tests with verbose output
```bash
pytest -v
```

### Run specific test file
```bash
pytest tests/test_main.py
```

### Run specific test class
```bash
pytest tests/test_main.py::TestHealthEndpoint
```

### Run specific test
```bash
pytest tests/test_main.py::TestHealthEndpoint::test_health_returns_ok
```

## Code Coverage

### Generate coverage report (terminal output)
```bash
pytest --cov=app --cov-report=term-missing
```

### Generate HTML coverage report
```bash
pytest --cov=app --cov-report=html
```
Then open `htmlcov/index.html` in your browser to view the detailed coverage report.

### Generate XML coverage report (for CI/CD)
```bash
pytest --cov=app --cov-report=xml
```

### Generate multiple coverage reports
```bash
pytest --cov=app --cov-report=term-missing --cov-report=html --cov-report=xml
```

## Configuration Files

### `.coveragerc`
Configuration for code coverage measurement. Specifies:
- Source files to measure (`app/`)
- Lines to exclude from coverage (e.g., `__repr__`, abstract methods)
- Report output format and precision

### `pytest.ini`
Configuration for pytest. Specifies:
- Test discovery patterns
- Default command-line options
- Custom markers for test categorization

### `conftest.py`
Pytest configuration file that provides:
- Shared fixtures (e.g., `client` fixture for FastAPI test client)
- Shared test utilities
- Plugin configuration

## Test Structure

Tests are organized into classes by endpoint:

- **TestRootEndpoint**: Tests for `/` endpoint
- **TestHealthEndpoint**: Tests for `/health` endpoint  
- **TestHelloEndpoint**: Tests for `/hello` endpoint
- **TestEchoEndpoint**: Tests for `/echo` endpoint
- **TestEchoModel**: Tests for Echo Pydantic model
- **TestAppMetadata**: Tests for app configuration
- **TestResponseFormats**: Tests for response format consistency

## Test Coverage

The test suite includes:
- ✓ All endpoints (GET and POST)
- ✓ Default parameter values
- ✓ Custom parameter values
- ✓ Edge cases (empty strings, special characters, unicode)
- ✓ Input validation (missing fields, wrong types)
- ✓ Response format validation (JSON headers)
- ✓ App metadata validation (title, version)
- ✓ Model validation (Pydantic)

## Integration with CI/CD

For Azure Pipelines or other CI/CD, use:
```bash
pytest --cov=app --cov-report=xml --cov-report=term-missing
```

This generates an XML report that can be published to coverage services.

## Tips

- Run tests frequently during development
- Always check coverage reports to identify untested code paths
- Use `-v` flag for detailed output when debugging
- Use `--lf` (last failed) to re-run only failed tests
- Use `-k` to filter tests by name pattern: `pytest -k "test_hello"`
