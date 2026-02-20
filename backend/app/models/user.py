from sqlalchemy import Boolean, Column, Integer, String, Enum, Text
from sqlalchemy.orm import relationship
from ..database import Base
import enum

class UserRole(str, enum.Enum):
    worker = "worker"
    contractor = "contractor"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    role = Column(Enum(UserRole))
    phone = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    face_embedding = Column(Text, nullable=True)
    profile_photo_url = Column(String, nullable=True)

    attendance = relationship("Attendance", back_populates="user")
