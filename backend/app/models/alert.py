from sqlalchemy import Column, Integer, String, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from ..database import Base

class Alert(Base):
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, index=True)
    site_id = Column(Integer, ForeignKey("sites.id"))
    severity = Column(String)
    message = Column(String)
    is_resolved = Column(Boolean, default=False)

    site = relationship("Site", back_populates="alerts")
