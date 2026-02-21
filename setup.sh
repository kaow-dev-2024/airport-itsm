
#!/bin/bash

echo "========================================="
echo "✈️  AIRPORT ENTERPRISE ITSM SETUP"
echo "========================================="

ROOT="airport-itsm"

mkdir $ROOT
cd $ROOT

############################################
# DOCKER COMPOSE
############################################
cat <<EOF > docker-compose.yml
version: "3.9"

services:

  postgres:
    image: postgres:15
    container_name: airport_postgres
    environment:
      POSTGRES_DB: airport_itsm
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    container_name: airport_redis
    ports:
      - "6379:6379"

  backend:
    build: ./backend
    container_name: airport_backend
    depends_on:
      - postgres
      - redis
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app

  frontend:
    build: ./frontend
    container_name: airport_frontend
    ports:
      - "5173:5173"
    volumes:
      - ./frontend:/app

volumes:
  db_data:
EOF

############################################
# BACKEND
############################################
mkdir backend
cd backend

cat <<EOF > Dockerfile
FROM python:3.11

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn","main:app","--host","0.0.0.0","--port","8000","--reload"]
EOF

cat <<EOF > requirements.txt
fastapi
uvicorn
sqlalchemy
psycopg2-binary
python-dotenv
pydantic
redis
EOF

############################################
# FASTAPI APP
############################################
cat <<EOF > main.py
from fastapi import FastAPI
from database import Base, engine
from routers import tickets

app = FastAPI(title="Airport ITSM")

Base.metadata.create_all(bind=engine)

app.include_router(tickets.router)

@app.get("/")
def root():
    return {"system":"Airport ITSM Running"}
EOF

############################################
# DATABASE
############################################
cat <<EOF > database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL="postgresql://admin:admin@postgres/airport_itsm"

engine=create_engine(DATABASE_URL)
SessionLocal=sessionmaker(bind=engine)
Base=declarative_base()
EOF

############################################
# MODELS
############################################
cat <<EOF > models.py
from sqlalchemy import Column,Integer,String,DateTime
from datetime import datetime
from database import Base

class Ticket(Base):
    tablename="tickets"

    id=Column(Integer,primary_key=True,index=True)
    title=Column(String)
    status=Column(String,default="OPEN")
    priority=Column(String,default="P3")
    created_at=Column(DateTime,default=datetime.utcnow)
EOF

############################################
# ROUTERS
############################################
mkdir routers

cat <<EOF > routers/tickets.py
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
EOF

cd ..

############################################
# FRONTEND
############################################
npm create vite@latest frontend -- --template vue

cd frontend
npm install
npm install vuetify axios

cat <<EOF > Dockerfile
FROM node:20

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

CMD ["npm","run","dev","--","--host"]
EOF

############################################
# SIMPLE UI
############################################
cat <<EOF > src/App.vue
<template>
<div style="padding:40px">
<h1>✈️ Airport IT Support</h1>

<input v-model="title" placeholder="Issue title"/>
<button @click="create">Create Ticket</button>

<ul>
<li v-for="t in tickets" :key="t.id">
{{t.id}} - {{t.title}} - {{t.status}}
</li>
</ul>

</div>
</template>

<script setup>
import {ref,onMounted} from "vue"
import axios from "axios"

const title=ref("")
const tickets=ref([])

const load=async()=>{
 const r=await axios.get("http://localhost:8000/tickets/")
 tickets.value=r.data
}

const create=async()=>{
 await axios.post("http://localhost:8000/tickets/?title="+title.value)
 load()
}

onMounted(load)
</script>
EOF

cd ..

############################################
echo "✅ PROJECT CREATED"
echo ""
echo "RUN:"
echo "docker compose up --build"
echo ""
echo "Frontend: http://localhost:5173"
echo "API Docs: http://localhost:8000/docs"
echo "===============