from app.routers.auth import router as auth_router
from app.routers.users import router as users_router
from app.routers.menu import router as menu_router
from app.routers.additionals import router as additionals_router
from app.routers.tables import router as tables_router
from app.routers.orders import router as orders_router
from app.routers.payments import router as payments_router
from app.routers.cash_drawer import router as cash_drawer_router
from app.routers.audit import router as audit_router
from app.routers.ws import router as ws_router

__all__ = [
    "auth_router",
    "users_router",
    "menu_router",
    "additionals_router",
    "tables_router",
    "orders_router",
    "payments_router",
    "cash_drawer_router",
    "audit_router",
    "ws_router",
]
