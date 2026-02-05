from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
from fastapi import Depends

from sqlalchemy.orm import Session

import traceback
import logging

from db.base import get_db

from core.config import settings

api_router = APIRouter()

logger = logging.getLogger(settings.PROJECT_NAME)


@api_router.post("/create-user")
@api_router.get("/create-user")
async def create_user(request: Request, db: Session = Depends(get_db)):
    try:
        payload = await request.json()
        headers = request.headers
        return {"status": "ok", "payload": payload, "headers": dict(headers)}

    except Exception as e:
        logger.info(f"{request.method} {request.url.path} - Status: 500")
        logger.error(
            f"Internal Server Error during Create User - {traceback.format_exc()}"
        )
        return JSONResponse(
            status_code=500,
            content={
                "error": f"Internal Server Error",
            },
        )
