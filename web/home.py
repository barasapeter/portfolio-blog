from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from api import deps
from schemas.item import Item, ItemCreate, ItemUpdate
from models.item import Item as ItemModel
from pathlib import Path
from fastapi.templating import Jinja2Templates


router = APIRouter()

BASE_DIR = Path(__file__).resolve().parent.parent
templates = Jinja2Templates(directory=BASE_DIR / "templates")

@router.get("/")
def root(request: Request):
    return templates.TemplateResponse("/index.html", {"request": request})