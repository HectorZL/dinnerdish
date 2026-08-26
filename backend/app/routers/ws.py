import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.core.websocket_manager import ws_manager

logger = logging.getLogger("ws_router")
router = APIRouter(tags=["websockets"])

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await ws_manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            # Echo or handle incoming client pings
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception as e:
        logger.warning(f"WebSocket connection error: {e}")
        ws_manager.disconnect(websocket)

@router.websocket("/api/ws")
async def api_websocket_endpoint(websocket: WebSocket):
    await websocket_endpoint(websocket)
