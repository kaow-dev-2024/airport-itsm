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
