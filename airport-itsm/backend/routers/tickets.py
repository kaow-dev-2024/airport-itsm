from fastapi import APIRouter
from database import SessionLocal
from models import Ticket

router=APIRouter(prefix="/tickets")

@router.post("/")
def create_ticket(title:str):
    db=SessionLocal()
    t=Ticket(title=title)
    db.add(t)
    db.commit()
    return {"message":"ticket created"}

@router.get("/")
def list_ticket():
    db=SessionLocal()
    return db.query(Ticket).all()
