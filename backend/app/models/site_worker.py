from sqlalchemy import Column, Integer, ForeignKey
from ..database import Base


class SiteWorker(Base):
    __tablename__ = "site_workers"

    id = Column(Integer, primary_key=True, index=True)
    site_id = Column(Integer, ForeignKey("sites.id"))
    worker_id = Column(Integer, ForeignKey("users.id"))
