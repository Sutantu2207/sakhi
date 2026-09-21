import pytest
import os
import sys
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

root_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if root_dir not in sys.path:
    sys.path.append(root_dir)

from backend.app.main import app
from backend.app.db.session import Base, get_db
import backend.app.db.base
from backend.app.core.security import get_password_hash, create_access_token
from backend.app.models.user import User, UserRole

# Use an in-memory SQLite database for fast isolated tests
TEST_DB_URL = "sqlite:///:memory:"

test_engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def db_session():
    connection = test_engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture
def test_user(db_session):
    user = User(
        email="testuser@sakhi.network",
        phone="+919999911111",
        full_name="Ananya Sen",
        hashed_password=get_password_hash("TestPass123!"),
        role=UserRole.USER,
        is_active=True,
        safety_network_opt_in=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def test_admin(db_session):
    admin = User(
        email="superadmin@sakhi.network",
        phone="+919999922222",
        full_name="Operations Admin",
        hashed_password=get_password_hash("AdminPass123!"),
        role=UserRole.ADMIN,
        is_active=True
    )
    db_session.add(admin)
    db_session.commit()
    db_session.refresh(admin)
    return admin


@pytest.fixture
def user_headers(test_user):
    token = create_access_token({"sub": test_user.id, "email": test_user.email, "role": test_user.role.value})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def admin_headers(test_admin):
    token = create_access_token({"sub": test_admin.id, "email": test_admin.email, "role": test_admin.role.value})
    return {"Authorization": f"Bearer {token}"}
