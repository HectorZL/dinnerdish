import logging
from sqlalchemy.orm import Session
from app.models.user import UserDB
from app.models.table import TableDB
from app.models.menu import MenuItemDB, GlobalAdditionalDB
from app.core.security import get_password_hash
from app.config import settings

logger = logging.getLogger("seed")

def seed_database(db: Session):
    # 1. Seed Admin User
    admin = db.query(UserDB).filter(UserDB.username == settings.ADMIN_USERNAME).first()
    if not admin:
        admin_user = UserDB(
            id="admin-user-001",
            username=settings.ADMIN_USERNAME,
            name=settings.ADMIN_NAME,
            email="admin@dinnerhome.com",
            hashed_password=get_password_hash(settings.ADMIN_PASSWORD),
            roles=["admin"],
            is_active=True,
        )
        db.add(admin_user)
        logger.info(f"Created default admin user '{settings.ADMIN_USERNAME}'")
    else:
        admin.hashed_password = get_password_hash(settings.ADMIN_PASSWORD)
        admin.is_active = True
        admin.roles = ["admin"]

    # Sample staff users
    sample_users = [
        ("admin", "Administrador", "admin123", ["admin"]),
        ("admin1", "Administrador Principal", "admin123", ["admin"]),
        ("mesero", "Juan Mesero", "mesero123", ["mesero"]),
        ("mesero1", "Carlos Mesero", "mesero123", ["mesero"]),
        ("cajero", "Maria Cajera", "cajero123", ["cajero"]),
        ("cajero1", "Ana Cajera", "cajero123", ["cajero"]),
        ("cocinero", "Carlos Cocinero", "cocinero123", ["cocinero"]),
        ("cocinero1", "Chef Mario", "cocinero123", ["cocinero"]),
    ]
    for username, name, pwd, roles in sample_users:
        existing = db.query(UserDB).filter(UserDB.username == username).first()
        if not existing:
            u = UserDB(
                id=f"user-{username}",
                username=username,
                name=name,
                email=f"{username}@dinnerhome.com",
                hashed_password=get_password_hash(pwd),
                roles=roles,
                is_active=True,
            )
            db.add(u)
        else:
            existing.hashed_password = get_password_hash(pwd)
            existing.is_active = True
            existing.roles = roles

    # 2. Seed Default Tables
    if db.query(TableDB).count() == 0:
        default_tables = [
            TableDB(id="table-01", number=1, seats=2, status="available", section="Terraza"),
            TableDB(id="table-02", number=2, seats=4, status="available", section="Terraza"),
            TableDB(id="table-03", number=3, seats=4, status="available", section="Salón Principal"),
            TableDB(id="table-04", number=4, seats=4, status="available", section="Salón Principal"),
            TableDB(id="table-05", number=5, seats=6, status="available", section="Salón Principal"),
            TableDB(id="table-06", number=6, seats=8, status="available", section="VIP"),
            TableDB(id="table-07", number=7, seats=2, status="available", section="Barra"),
            TableDB(id="table-08", number=8, seats=2, status="available", section="Barra"),
        ]
        db.add_all(default_tables)
        logger.info("Seeded default tables")

    # 3. Seed Global Additionals
    if db.query(GlobalAdditionalDB).count() == 0:
        default_additionals = [
            GlobalAdditionalDB(id="add-queso", name="Queso Extra", price_cents=250, available=True),
            GlobalAdditionalDB(id="add-tocineta", name="Tocineta Crujiente", price_cents=350, available=True),
            GlobalAdditionalDB(id="add-aguacate", name="Porción de Aguacate", price_cents=300, available=True),
            GlobalAdditionalDB(id="add-papas", name="Papas Fritas Extra", price_cents=400, available=True),
            GlobalAdditionalDB(id="add-salsa", name="Salsa de la Casa", price_cents=150, available=True),
        ]
        db.add_all(default_additionals)
        logger.info("Seeded default global additionals")

    # 4. Seed Default Menu Items
    if db.query(MenuItemDB).count() == 0:
        default_menu = [
            MenuItemDB(
                id="menu-01",
                name="Hamburguesa DinnerHome Clásica",
                price_cents=1250,
                category="Hamburguesas",
                available=True,
                stock=50,
                modifiers=[
                    {"id": "mod-01", "name": "Sin Cebolla", "priceCents": 0},
                    {"id": "mod-02", "name": "Término Medio", "priceCents": 0},
                    {"id": "mod-03", "name": "Bien Cocida", "priceCents": 0},
                ],
                variations=[
                    {"id": "var-01", "name": "Sencilla", "priceCents": 1250, "stock": 30},
                    {"id": "var-02", "name": "Doble Carne", "priceCents": 1650, "stock": 20},
                ],
                additional_ids=["add-queso", "add-tocineta", "add-papas"],
            ),
            MenuItemDB(
                id="menu-02",
                name="Pizza Artesanal Margherita",
                price_cents=1500,
                category="Pizzas",
                available=True,
                stock=30,
                modifiers=[
                    {"id": "mod-04", "name": "Masa Delgada", "priceCents": 0},
                    {"id": "mod-05", "name": "Masa Gruesa", "priceCents": 0},
                ],
                variations=[
                    {"id": "var-03", "name": "Mediana (8 Porciones)", "priceCents": 1500, "stock": 15},
                    {"id": "var-04", "name": "Grande (12 Porciones)", "priceCents": 2100, "stock": 15},
                ],
                additional_ids=["add-queso", "add-tocineta"],
            ),
            MenuItemDB(
                id="menu-03",
                name="Tacos al Pastor (3 uds)",
                price_cents=950,
                category="Entradas",
                available=True,
                stock=40,
                modifiers=[
                    {"id": "mod-06", "name": "Con Piña", "priceCents": 0},
                    {"id": "mod-07", "name": "Sin Picante", "priceCents": 0},
                ],
                variations=[],
                additional_ids=["add-aguacate", "add-salsa"],
            ),
            MenuItemDB(
                id="menu-04",
                name="Ensalada César con Pollo Grillé",
                price_cents=1100,
                category="Ensaladas",
                available=True,
                stock=25,
                modifiers=[],
                variations=[],
                additional_ids=["add-queso", "add-aguacate"],
            ),
            MenuItemDB(
                id="menu-05",
                name="Limonada Natural",
                price_cents=400,
                category="Bebidas",
                available=True,
                stock=100,
                modifiers=[
                    {"id": "mod-08", "name": "Baja en Azúcar", "priceCents": 0},
                    {"id": "mod-09", "name": "Sin Hielo", "priceCents": 0},
                ],
                variations=[
                    {"id": "var-05", "name": "Vaso 16oz", "priceCents": 400, "stock": 60},
                    {"id": "var-06", "name": "Jarra 1L", "priceCents": 900, "stock": 40},
                ],
                additional_ids=[],
            ),
            MenuItemDB(
                id="menu-06",
                name="Cerveza Artesanal",
                price_cents=600,
                category="Bebidas",
                available=True,
                stock=80,
                modifiers=[],
                variations=[
                    {"id": "var-07", "name": "Rubia / Blonde Ale", "priceCents": 600, "stock": 40},
                    {"id": "var-08", "name": "IPA", "priceCents": 650, "stock": 40},
                ],
                additional_ids=[],
            ),
            MenuItemDB(
                id="menu-07",
                name="Brownie con Helado de Vainilla",
                price_cents=700,
                category="Postres",
                available=True,
                stock=20,
                modifiers=[],
                variations=[],
                additional_ids=[],
            ),
        ]
        db.add_all(default_menu)
        logger.info("Seeded default menu items")

    db.commit()
