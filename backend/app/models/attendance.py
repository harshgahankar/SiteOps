from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Float, Boolean
from sqlalchemy.orm import relationship
from ..database import Base
import datetime

class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    site_id = Column(Integer, ForeignKey("sites.id"))
    check_in = Column(DateTime, default=datetime.datetime.utcnow)
    check_out = Column(DateTime, nullable=True)
    location_lat = Column(Float)
    location_lng = Column(Float)
    device_info = Column(String)
    biometric_verified = Column(Boolean)
    total_wage = Column(Float, default=0.0)
    total_duration_seconds = Column(Integer, default=0)

    user = relationship("User", back_populates="attendance")
    site = relationship("Site", back_populates="attendance")
