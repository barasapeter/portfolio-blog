from fastapi import FastAPI
from api.v1.api import api_router
from core.config import settings
from web.home import router as home_router
from fastapi.staticfiles import StaticFiles

from contextlib import asynccontextmanager
import socket

from db.base_class import Base
from db.session import engine

from db.session import SessionLocal
from db import User, Category, Tag, Post, PostStatus


def init_db():
    Base.metadata.create_all(bind=engine)


def drop_db():
    print("DB Dropped, please restart...")
    Base.metadata.drop_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()

    db = SessionLocal()
    try:
        if not db.query(User).filter_by(username="admin").first():
            user = User(
                username="admin",
                email="admin@example.com",
                password_hash="hashed_password_here",
                full_name="Administrator",
                bio="The first admin user",
            )
            db.add(user)
            db.commit()
            db.refresh(user)

            category = Category(
                name="General", slug="general", description="General posts"
            )
            db.add(category)
            db.commit()
            db.refresh(category)

            tag = Tag(name="Introduction", slug="introduction")
            db.add(tag)
            db.commit()
            db.refresh(tag)

            post = Post(
                title="Welcome to the Blog!",
                slug="welcome-to-the-blog",
                excerpt="This is the first post in the blog.",
                content="Hello world! This is the very first post.",
                author_id=user.id,
                category_id=category.id,
                status=PostStatus.PUBLISHED,
            )
            post.tags.append(tag)
            db.add(post)
            db.commit()

            print("Dummy data inserted successfully")
        else:
            print("Dummy data already exists, skipping...")
    finally:
        db.close()

    yield

    print("🛑 App is shutting down...")


app = FastAPI(
    title=settings.PROJECT_NAME,
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
    lifespan=lifespan,
)

app.mount("/static", StaticFiles(directory="static"), name="static")

app.include_router(api_router, prefix=settings.API_V1_STR)
app.include_router(home_router, prefix="")


if __name__ == "__main__":
    import uvicorn

    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    port = 5000

    print(f"http://127.0.0.1:{port}")
    print(f"LAN http://{local_ip}:{port}")

    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
