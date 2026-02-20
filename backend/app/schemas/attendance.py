from pydantic import BaseModel
from typing import Optional
import datetime

class AttendanceBase(BaseModel):
    site_id: int
    location_lat: float
    location_lng: float
    device_info: str
    biometric_verified: bool

class AttendanceCreate(AttendanceBase):
    pass

class AttendanceCheckOut(BaseModel):
    attendance_id: int

class Attendance(AttendanceBase):
    id: int
    user_id: int
    check_in: datetime.datetime
    check_out: Optional[datetime.datetime] = None
    total_wage: float
    total_duration_seconds: int

    class Config:
        orm_mode = True
