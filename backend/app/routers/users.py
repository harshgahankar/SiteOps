from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from .. import schemas, models
from ..database import get_db
from ..utils.dependencies import get_current_user
import os
from pathlib import Path


router = APIRouter()


@router.put("/update-profile", response_model=schemas.User)
def update_profile(
    user_update: schemas.UserUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    for key, value in user_update.dict(exclude_unset=True).items():
        setattr(current_user, key, value)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/upload-photo", response_model=schemas.User)
async def upload_photo(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    media_root = Path("media/profile_photos")
    media_root.mkdir(parents=True, exist_ok=True)

    ext = os.path.splitext(file.filename or "")[1] or ".jpg"
    filename = f"user_{current_user.id}{ext}"
    file_path = media_root / filename

    with file_path.open("wb") as f:
        content = await file.read()
        f.write(content)

    current_user.profile_photo_url = f"/media/profile_photos/{filename}"
    db.commit()
    db.refresh(current_user)
    return current_user

