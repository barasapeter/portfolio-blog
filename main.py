from fastapi import FastAPI
from api.v1.api import api_router
from core.config import settings
from web.home import router as home_router
from fastapi.staticfiles import StaticFiles

app = FastAPI(title=settings.PROJECT_NAME, docs_url=None, redoc_url=None, openapi_url=None)

app.mount("/static", StaticFiles(directory="static"), name="static")

app.include_router(api_router, prefix=settings.API_V1_STR)
app.include_router(home_router, prefix="")



if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", reload=True)
