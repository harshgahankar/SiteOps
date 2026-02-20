from pydantic import BaseModel
from typing import Optional
import datetime

class SiteBase(BaseModel):
    name: str
    location: str
    start_date: Optional[datetime.datetime] = None
    description: Optional[str] = None

class SiteCreate(SiteBase):
    pass

class SiteUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    start_date: Optional[datetime.datetime] = None
    description: Optional[str] = None

class Site(SiteBase):
    id: int
    contractor_id: int

    class Config:
        orm_mode = True
