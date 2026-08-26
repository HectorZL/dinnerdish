import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base, SessionLocal
from app.seed import seed_database
from app.routers import (
    auth_router,
    users_router,
    menu_router,
    additionals_router,
    tables_router,
    orders_router,
    payments_router,
    cash_drawer_router,
    audit_router,
    ws_router,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Ensure tables exist & seed default data
    logger.info("Initializing database tables...")
    Base.metadata.create_all(bind=engine)
    
    logger.info("Checking & applying seed data...")
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()
    
    yield
    # Shutdown logic if any
    logger.info("Shutting down application...")

app = FastAPI(
    title="DinnerHome POS API",
    description="Backend API and WebSocket real-time engine for DinnerHome Restaurant POS",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS Configuration
origins = settings.cors_origins_list
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if origins != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(menu_router)
app.include_router(additionals_router)
app.include_router(tables_router)
app.include_router(orders_router)
app.include_router(payments_router)
app.include_router(cash_drawer_router)
app.include_router(audit_router)
app.include_router(ws_router)

@app.get("/health", tags=["system"])
def health_check():
    return {
        "status": "healthy",
        "service": "dinnerhome-api",
        "env": settings.ENV,
        "database": "connected"
    }

@app.get("/", tags=["system"])
def root():
    return {
        "name": "DinnerHome POS API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
        "websocket": "/ws"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=True)
