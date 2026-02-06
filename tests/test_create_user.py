import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from main import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_create_user_success():
    payload = {
        "username": "peter_barasa",
        "full_name": "Peter Barasa",
        "email": "peter@example.com",
        "password": "StrongPass1",
    }
    response = client.post("/api/v1/create-user", json=payload)
    assert response.status_code == 200
    assert response.json()["status"] == "User created successfully"


def test_missing_username():
    payload = {
        "full_name": "Peter Barasa",
        "email": "peter@example.com",
        "password": "StrongPass1",
    }
    response = client.post("/api/v1/create-user", json=payload)
    assert response.status_code == 400
    assert "Missing mandatory fields" in response.json()["error"]


def test_missing_email_and_password():
    payload = {"username": "peter_barasa", "full_name": "Peter Barasa"}
    response = client.post("/api/v1/create-user", json=payload)
    assert response.status_code == 400
    assert response.json()["error"] == "Either email or password must be provided"


def test_invalid_username():
    payload = {
        "username": "ab",
        "full_name": "Peter Barasa",
        "email": "peter@example.com",
        "password": "StrongPass1",
    }
    response = client.post("/api/v1/create-user", json=payload)
    assert response.status_code == 400


def test_invalid_password():
    payload = {
        "username": "peter_barasa",
        "full_name": "Peter Barasa",
        "email": "peter@example.com",
        "password": "weak",
    }
    response = client.post("/api/v1/create-user", json=payload)
    assert response.status_code == 400
