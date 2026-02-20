from pydantic import BaseModel
from typing import Optional

class InventoryItemBase(BaseModel):
    name: str
    category: str
    status: str
    site_id: int

class InventoryItemCreate(InventoryItemBase):
    pass

class InventoryItemUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    status: Optional[str] = None

class InventoryItem(InventoryItemBase):
    id: int

    class Config:
        orm_mode = True
