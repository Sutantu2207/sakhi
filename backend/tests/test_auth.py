def test_register_user_success(client):
    res = client.post("/api/v1/auth/register", json={
        "email": "newuser@sakhi.network",
        "password": "Password123!",
        "full_name": "Kavita Rao",
        "phone": "+919123456789"
    })
    assert res.status_code == 201
    data = res.json()
    assert data["email"] == "newuser@sakhi.network"
    assert data["full_name"] == "Kavita Rao"
    assert "hashed_password" not in data


def test_register_duplicate_email(client, test_user):
    res = client.post("/api/v1/auth/register", json={
        "email": test_user.email,
        "password": "Password123!",
        "full_name": "Another Name"
    })
    assert res.status_code == 409


def test_login_success(client, test_user):
    res = client.post("/api/v1/auth/login", json={
        "email": test_user.email,
        "password": "TestPass123!"
    })
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert data["user_id"] == test_user.id


def test_login_invalid_password(client, test_user):
    res = client.post("/api/v1/auth/login", json={
        "email": test_user.email,
        "password": "WrongPassword!"
    })
    assert res.status_code == 401


def test_get_current_user_me(client, user_headers, test_user):
    res = client.get("/api/v1/auth/me", headers=user_headers)
    assert res.status_code == 200
    assert res.json()["id"] == test_user.id


def test_update_privacy_settings(client, user_headers):
    res = client.put("/api/v1/auth/privacy-settings", headers=user_headers, json={
        "safety_network_opt_in": False,
        "location_retention_days": 14
    })
    assert res.status_code == 200
    data = res.json()
    assert data["safety_network_opt_in"] is False
    assert data["location_retention_days"] == 14
