from pydantic import BaseModel
from typing import Optional

class AlertBase(BaseModel):
    site_id: int
    severity: str
    message: str

class AlertCreate(AlertBase):
    pass

class AlertUpdate(BaseModel):
    is_resolved: bool

class Alert(AlertBase):
    id: int
    is_resolved: bool

    class Config:
        orm_mode = True
