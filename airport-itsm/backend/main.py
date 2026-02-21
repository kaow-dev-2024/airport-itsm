from fastapi import FastAPI
from database import Base, engine
from routers import tickets

app = FastAPI(title="Airport ITSM")

Base.metadata.create_all(bind=engine)

app.include_router(tickets.router)

@app.get("/")
def root():
    return {"system":"Airport ITSM Running"}
