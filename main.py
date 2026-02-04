from fastapi import FastAPI
from api.v1.api import api_router
from core.config import settings
from web.home import router as home_router

app = FastAPI(title=settings.PROJECT_NAME)

app.include_router(api_router, prefix=settings.API_V1_STR)
app.include_router(home_router, prefix="")



if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", reload=True)
