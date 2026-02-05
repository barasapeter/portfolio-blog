# Building My Blogging App: Lessons Learned 

# Logging
## Introduction

This blog post is about my experience creating my new blogging app from scratch. The purpose of this project is not only to create a working application, but also to show off my system design, logging, api security, and clean coding standards skills as a software engineer (all important parts of being a good software engineer).

I am writing this blog post to focus primarily on logging, what I learned about logging, how I implemented logging, and why logging is important in developing production level applications.

---


## Logging

Initially, I only used `print` statements for debugging. However, as the project grew, I realized:

- `print` is **not scalable** for monitoring real applications.
- Logs should provide **context**, **severity levels**, and **persistence** for post-mortem analysis.

I studied Python’s built-in **logging module** and learned how to:

- Use **different log levels** (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Write logs to a **file**, not just the console
- Track **unique errors** to prevent log flooding
- Log **API requests and responses** without exposing sensitive information

---

## Implementing Logging in My App

I implemented a centralized logging system:

1. **Configured a global logger** in `main.py`:

```python
os.makedirs("logs", exist_ok=True)

logging.basicConfig(
    filename="logs/app.log",
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(settings.PROJECT_NAME)

app = FastAPI(
    title=settings.PROJECT_NAME,
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
    lifespan=lifespan,
)
````

2. **Used the logger in modular routers**, like `routers/posts.py`:

```python
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
```

3. **Added middleware to log all requests and responses**:

* Tracks method, path, response status, and execution time
* Deduplicates errors to avoid log flooding

---

