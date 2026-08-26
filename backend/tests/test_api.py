import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database import Base, get_db
from app.seed import seed_database

TEST_DB_PATH = "./test_api.db"
TEST_DATABASE_URL = f"sqlite:///{TEST_DB_PATH}"

test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass

    Base.metadata.create_all(bind=test_engine)
    db = TestingSessionLocal()
    seed_database(db)
    db.close()
    
    yield
    
    Base.metadata.drop_all(bind=test_engine)
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass

@pytest.fixture
def client():
    return TestClient(app)

def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_admin_login(client):
    response = client.post("/api/auth/login", json={
        "username": "admin",
        "password": "admin123"
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["username"] == "admin"
    assert "admin" in data["user"]["roles"]

def test_user_crud_and_roles(client):
    # Admin login
    admin_token = client.post("/api/auth/login", json={
        "username": "admin",
        "password": "admin123"
    }).json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # Create new user
    create_res = client.post("/api/users", json={
        "username": "nuevo_cajero",
        "name": "Pedro Cajero",
        "password": "password123",
        "roles": ["cajero"],
        "isActive": True
    }, headers=admin_headers)
    assert create_res.status_code == 200
    user_data = create_res.json()
    user_id = user_data["id"]
    assert user_data["username"] == "nuevo_cajero"

    # List users
    users_res = client.get("/api/users", headers=admin_headers)
    assert users_res.status_code == 200
    assert any(u["id"] == user_id for u in users_res.json())

    # Update user
    update_res = client.put(f"/api/users/{user_id}", json={
        "name": "Pedro Antonio Cajero",
        "isActive": True
    }, headers=admin_headers)
    assert update_res.status_code == 200
    assert update_res.json()["name"] == "Pedro Antonio Cajero"

    # Delete user
    del_res = client.delete(f"/api/users/{user_id}", headers=admin_headers)
    assert del_res.status_code == 200

def test_get_menu_and_stock_adjustment(client):
    admin_token = client.post("/api/auth/login", json={
        "username": "admin",
        "password": "admin123"
    }).json()["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    response = client.get("/api/menu")
    assert response.status_code == 200
    items = response.json()
    assert len(items) > 0
    
    first_item = items[0]
    initial_stock = first_item["stock"]

    # Adjust stock +5
    adjust_res = client.post(f"/api/menu/{first_item['id']}/stock", json={
        "quantityChange": 5
    }, headers=headers)
    assert adjust_res.status_code == 200
    assert adjust_res.json()["stock"] == initial_stock + 5

def test_additionals_and_assignments(client):
    admin_token = client.post("/api/auth/login", json={
        "username": "admin",
        "password": "admin123"
    }).json()["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Create global additional
    add_res = client.post("/api/additionals", json={
        "name": "Jalapeños Extra",
        "priceCents": 180,
        "available": True
    }, headers=headers)
    assert add_res.status_code == 200
    additional = add_res.json()
    add_id = additional["id"]

    # Assign to menu item
    assign_res = client.post("/api/additionals/assignments", json={
        "menuItemId": "menu-01",
        "source": "global",
        "additionalId": add_id
    }, headers=headers)
    assert assign_res.status_code == 200

    # Verify assigned additionals list
    assigned_res = client.get("/api/additionals/assigned/menu-01")
    assert assigned_res.status_code == 200
    assigned_items = assigned_res.json()
    assert any(a["additionalId"] == add_id for a in assigned_items)

def test_get_tables_and_status(client):
    admin_token = client.post("/api/auth/login", json={
        "username": "admin",
        "password": "admin123"
    }).json()["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    response = client.get("/api/tables")
    assert response.status_code == 200
    tables = response.json()
    assert len(tables) >= 8

    # Update table status
    update_res = client.put(f"/api/tables/{tables[0]['id']}/status", json={
        "status": "reserved"
    }, headers=headers)
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "reserved"

def test_order_lifecycle_and_payments(client):
    # 1. Login as waiter
    login_res = client.post("/api/auth/login", json={
        "username": "mesero1",
        "password": "mesero123"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create draft order
    order_res = client.post("/api/orders/draft", json={
        "waiterId": "user-mesero1",
        "tableId": "table-02"
    }, headers=headers)
    assert order_res.status_code == 200
    order = order_res.json()
    order_id = order["id"]
    assert order["status"] == "draft"

    # 3. Add item
    add_item_res = client.post(f"/api/orders/{order_id}/items", json={
        "item": {
            "id": "order-item-1",
            "menuItemId": "menu-01",
            "quantity": 2,
            "notes": "Bien cocidas",
            "status": "pending",
            "priceCents": 1250,
            "name": "Hamburguesa DinnerHome Clásica",
            "modifierIds": ["mod-03"],
            "selectedAdditionals": [
                {
                    "id": "add-sel-1",
                    "additionalId": "add-queso",
                    "name": "Queso Extra",
                    "priceCents": 250,
                    "source": "global"
                }
            ]
        }
    }, headers=headers)
    assert add_item_res.status_code == 200
    updated_order = add_item_res.json()
    assert updated_order["totalCents"] == 3000

    # 4. Send to kitchen
    send_res = client.post(f"/api/orders/{order_id}/send-to-kitchen", headers=headers)
    assert send_res.status_code == 200
    assert send_res.json()["status"] == "sentToKitchen"

    # 5. Process Payment
    pay_res = client.post("/api/payments/process", json={
        "orderId": order_id,
        "amountCents": 3000,
        "method": "card",
        "processedBy": "user-cajero1"
    }, headers=headers)
    assert pay_res.status_code == 200
    tx = pay_res.json()
    assert tx["status"] == "completed"

    # 6. Verify order closed
    final_order = client.get(f"/api/orders/{order_id}", headers=headers).json()
    assert final_order["status"] == "closed"

    # 7. Payment History & Summary
    history_res = client.get(f"/api/payments/history/{order_id}", headers=headers)
    assert history_res.status_code == 200
    assert len(history_res.json()) == 1

    summary_res = client.get("/api/payments/summary", headers=headers)
    assert summary_res.status_code == 200
    assert len(summary_res.json()) > 0

def test_cash_drawer_and_audit(client):
    admin_token = client.post("/api/auth/login", json={
        "username": "admin",
        "password": "admin123"
    }).json()["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Open Drawer
    open_res = client.post("/api/cash-drawer/open", json={
        "cashierId": "admin-user-001",
        "startingBalanceCents": 10000
    }, headers=headers)
    assert open_res.status_code == 200
    session = open_res.json()
    session_id = session["id"]

    # Close Drawer
    close_res = client.post("/api/cash-drawer/close", json={
        "sessionId": session_id,
        "actualBalanceCents": 10500
    }, headers=headers)
    assert close_res.status_code == 200
    assert close_res.json()["status"] == "closed"

    # Audit log verification
    audit_res = client.get("/api/audit", headers=headers)
    assert audit_res.status_code == 200
    entries = audit_res.json()
    assert len(entries) > 0
