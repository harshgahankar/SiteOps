from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
from ..database import Base

class Site(Base):
    __tablename__ = "sites"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    location = Column(String)
    start_date = Column(DateTime, nullable=True)
    description = Column(Text, nullable=True)
    contractor_id = Column(Integer, ForeignKey("users.id"))

    contractor = relationship("User")
    attendance = relationship("Attendance", back_populates="site")
    inventory = relationship("InventoryItem", back_populates="site")
    alerts = relationship("Alert", back_populates="site")
