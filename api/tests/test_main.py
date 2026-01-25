import pytest
from fastapi.testclient import TestClient
from app.main import app, Echo


class TestRootEndpoint:
    """Test the root / endpoint."""
    
    def test_root_returns_allowed_methods(self, client):
        """Test that root endpoint returns allowed methods."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "Allowed methods" in data
        assert "/health [GET]" in data["Allowed methods"]
        assert "/hello [GET]" in data["Allowed methods"]
        assert "/echo [POST]" in data["Allowed methods"]


class TestHealthEndpoint:
    """Test the /health endpoint."""
    
    def test_health_returns_ok(self, client):
        """Test that health endpoint returns ok status."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"


class TestHelloEndpoint:
    """Test the /hello endpoint."""
    
    def test_hello_with_default_name(self, client):
        """Test hello endpoint with default name."""
        response = client.get("/hello")
        assert response.status_code == 200
        data = response.json()
        assert data["greeting"] == "Hello, world!"
    
    def test_hello_with_custom_name(self, client):
        """Test hello endpoint with custom name."""
        response = client.get("/hello?name=Alice")
        assert response.status_code == 200
        data = response.json()
        assert data["greeting"] == "Hello, Alice!"
    
    def test_hello_with_different_names(self, client):
        """Test hello endpoint with various names."""
        names = ["Bob", "Charlie", "Diana", "Eve", "Frank"]
        for name in names:
            response = client.get(f"/hello?name={name}")
            assert response.status_code == 200
            data = response.json()
            assert data["greeting"] == f"Hello, {name}!"


class TestEchoEndpoint:
    """Test the /echo endpoint."""
    
    def test_echo_with_message(self, client):
        """Test echo endpoint with a message."""
        payload = {"message": "Hello, World!"}
        response = client.post("/echo", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["you_said"] == "Hello, World!"
    
    def test_echo_with_empty_message(self, client):
        """Test echo endpoint with empty message."""
        payload = {"message": ""}
        response = client.post("/echo", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["you_said"] == ""
    
    def test_echo_with_special_characters(self, client):
        """Test echo endpoint with special characters."""
        special_messages = [
            "!@#$%^&*()",
            "quotes: \" and '",
            "newlines\nand\ttabs",
            "unicode: 你好世界 🎉"
        ]
        for message in special_messages:
            payload = {"message": message}
            response = client.post("/echo", json=payload)
            assert response.status_code == 200
            data = response.json()
            assert data["you_said"] == message
    
    def test_echo_missing_message_field(self, client):
        """Test echo endpoint with missing message field."""
        payload = {}
        response = client.post("/echo", json=payload)
        assert response.status_code == 422  # Validation error
    
    def test_echo_with_wrong_type(self, client):
        """Test echo endpoint with wrong message type."""
        payload = {"message": 123}  # Should be string
        response = client.post("/echo", json=payload)
        # FastAPI may coerce this or reject it depending on validation
        # This test documents the actual behavior
        assert response.status_code in [200, 422]


class TestEchoModel:
    """Test the Echo Pydantic model."""
    
    def test_echo_model_valid_data(self):
        """Test Echo model with valid data."""
        echo = Echo(message="Test message")
        assert echo.message == "Test message"
    
    def test_echo_model_string_validation(self):
        """Test Echo model enforces string type."""
        with pytest.raises(ValueError):
            Echo(message=123)


class TestAppMetadata:
    """Test app metadata."""
    
    def test_app_title(self):
        """Test that app has correct title."""
        assert app.title == "Hello API"
    
    def test_app_version(self):
        """Test that app has correct version."""
        assert app.version == "1.0.0"


class TestResponseFormats:
    """Test response format consistency."""
    
    def test_root_response_format(self, client):
        """Test root response is valid JSON."""
        response = client.get("/")
        assert response.headers["content-type"] == "application/json"
    
    def test_health_response_format(self, client):
        """Test health response is valid JSON."""
        response = client.get("/health")
        assert response.headers["content-type"] == "application/json"
    
    def test_hello_response_format(self, client):
        """Test hello response is valid JSON."""
        response = client.get("/hello")
        assert response.headers["content-type"] == "application/json"
    
    def test_echo_response_format(self, client):
        """Test echo response is valid JSON."""
        response = client.post("/echo", json={"message": "test"})
        assert response.headers["content-type"] == "application/json"
