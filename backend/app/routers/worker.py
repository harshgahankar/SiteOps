from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from .. import schemas, models
from ..database import get_db
from ..utils.dependencies import get_current_user
from datetime import datetime
import numpy as np
import cv2
import json

router = APIRouter()

@router.get("/dashboard", response_model=schemas.user.User)
def get_worker_dashboard(current_user: models.User = Depends(get_current_user)):
    # In a real app, you'd return more dashboard-specific data
    return current_user


def _calculate_wage_details(check_in: datetime, check_out: datetime | None):
    end_time = check_out or datetime.utcnow()
    total_seconds = int((end_time - check_in).total_seconds())
    intervals = total_seconds // 15
    wage = float(intervals * 100)
    return wage, total_seconds


@router.post("/check-in", response_model=schemas.Attendance)
def check_in(attendance: schemas.AttendanceCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.worker:
        raise HTTPException(status_code=403, detail="Not authorized")
    assignment = (
        db.query(models.SiteWorker)
        .filter(
            models.SiteWorker.worker_id == current_user.id,
            models.SiteWorker.site_id == attendance.site_id,
        )
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=400, detail="Worker is not assigned to this site")
    if not attendance.biometric_verified:
        raise HTTPException(status_code=400, detail="Biometric verification required")
    open_record = (
        db.query(models.Attendance)
        .filter(models.Attendance.user_id == current_user.id, models.Attendance.check_out.is_(None))
        .first()
    )
    if open_record:
        raise HTTPException(status_code=400, detail="Worker already checked in")
    db_attendance = models.Attendance(**attendance.dict(), user_id=current_user.id)
    db.add(db_attendance)
    db.commit()
    db.refresh(db_attendance)
    return db_attendance

@router.post("/check-out", response_model=schemas.Attendance)
def check_out(attendance_checkout: schemas.AttendanceCheckOut, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.worker:
        raise HTTPException(status_code=403, detail="Not authorized")
    db_attendance = (
        db.query(models.Attendance)
        .filter(
            models.Attendance.id == attendance_checkout.attendance_id,
            models.Attendance.user_id == current_user.id,
        )
        .first()
    )
    if not db_attendance:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    if db_attendance.check_out is None:
        db_attendance.check_out = datetime.utcnow()
        wage, total_seconds = _calculate_wage_details(db_attendance.check_in, db_attendance.check_out)
        db_attendance.total_wage = wage
        db_attendance.total_duration_seconds = total_seconds
        db.commit()
        db.refresh(db_attendance)
    return db_attendance

@router.get("/attendance", response_model=list[schemas.Attendance])
def get_attendance_history(from_date: datetime | None = None, to_date: datetime | None = None, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    query = db.query(models.Attendance).filter(models.Attendance.user_id == current_user.id)
    if from_date:
        query = query.filter(models.Attendance.check_in >= from_date)
    if to_date:
        query = query.filter(models.Attendance.check_in <= to_date)
    return query.all()

@router.get("/wages")
def get_wage_summary(month: int | None = None, year: int | None = None, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.worker:
        raise HTTPException(status_code=403, detail="Not authorized")
    now = datetime.utcnow()
    if month is None:
        month = now.month
    if year is None:
        year = now.year
    start = datetime(year, month, 1)
    if month == 12:
        end = datetime(year + 1, 1, 1)
    else:
        end = datetime(year, month + 1, 1)
    records = (
        db.query(models.Attendance)
        .filter(
            models.Attendance.user_id == current_user.id,
            models.Attendance.check_in >= start,
            models.Attendance.check_in < end,
        )
        .all()
    )
    total_wage = 0.0
    total_seconds = 0
    for rec in records:
        if rec.check_out is None:
            wage, seconds = _calculate_wage_details(rec.check_in, None)
        else:
            if rec.total_duration_seconds and rec.total_wage:
                wage = rec.total_wage
                seconds = rec.total_duration_seconds
            else:
                wage, seconds = _calculate_wage_details(rec.check_in, rec.check_out)
        total_wage += wage
        total_seconds += seconds
    return {
        "month": month,
        "year": year,
        "total_wage": total_wage,
        "total_duration_seconds": total_seconds,
    }

@router.put("/profile", response_model=schemas.User)
def update_worker_profile(user_update: schemas.UserUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    for key, value in user_update.dict(exclude_unset=True).items():
        setattr(current_user, key, value)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.get("/my-site")
def get_my_site(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.worker:
        raise HTTPException(status_code=403, detail="Not authorized")
    assignment = (
        db.query(models.SiteWorker)
        .filter(models.SiteWorker.worker_id == current_user.id)
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=404, detail="Worker is not assigned to any site")
    site = db.query(models.Site).filter(models.Site.id == assignment.site_id).first()
    if not site:
        raise HTTPException(status_code=404, detail="Site not found")
    contractor = site.contractor
    contractor_name = contractor.full_name or contractor.username if contractor else None
    return {
        "site_id": site.id,
        "site_name": site.name,
        "site_location": site.location,
        "site_description": site.description,
        "contractor_id": site.contractor_id,
        "contractor_name": contractor_name,
    }


@router.get("/current-status")
def get_current_status(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.worker:
        raise HTTPException(status_code=403, detail="Not authorized")
    base_query = db.query(models.Attendance).filter(models.Attendance.user_id == current_user.id)
    current = base_query.filter(models.Attendance.check_out.is_(None)).order_by(models.Attendance.check_in.desc()).first()
    if current:
        wage, seconds = _calculate_wage_details(current.check_in, None)
        site = db.query(models.Site).filter(models.Site.id == current.site_id).first()
        return {
            "status": "checked_in",
            "attendance_id": current.id,
            "site_id": current.site_id,
            "site_name": site.name if site else None,
            "check_in_time": current.check_in,
            "check_out_time": current.check_out,
            "current_wage": wage,
            "total_duration_seconds": seconds,
        }
    last = base_query.order_by(models.Attendance.check_in.desc()).first()
    if not last:
        return {"status": "not_checked_in"}
    wage, seconds = _calculate_wage_details(last.check_in, last.check_out)
    site = db.query(models.Site).filter(models.Site.id == last.site_id).first()
    return {
        "status": "checked_out",
        "attendance_id": last.id,
        "site_id": last.site_id,
        "site_name": site.name if site else None,
        "check_in_time": last.check_in,
        "check_out_time": last.check_out,
        "last_wage": wage,
        "total_duration_seconds": seconds,
    }


def _read_image_to_array(file_bytes: bytes):
    nparr = np.frombuffer(file_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise HTTPException(status_code=400, detail="Invalid image file")
    return img


def _detect_single_face(image_array: np.ndarray):
    gray = cv2.cvtColor(image_array, cv2.COLOR_BGR2GRAY)
    cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
    faces = cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(60, 60))

    if len(faces) == 0:
        raise HTTPException(status_code=400, detail="No face detected")

    # Pick the largest bounding box as the main face.
    faces_list = faces.tolist()
    faces_list.sort(key=lambda b: b[2] * b[3], reverse=True)
    x, y, w, h = faces_list[0]

    # Only reject "multiple faces" if we find another box that is
    # clearly separate from the main one (very low overlap and not tiny).
    main_area = float(w * h)
    for (ox, oy, ow, oh) in faces_list[1:]:
        inter_x1 = max(x, ox)
        inter_y1 = max(y, oy)
        inter_x2 = min(x + w, ox + ow)
        inter_y2 = min(y + h, oy + oh)

        inter_w = max(0.0, inter_x2 - inter_x1)
        inter_h = max(0.0, inter_y2 - inter_y1)
        inter_area = inter_w * inter_h

        other_area = float(ow * oh)
        union_area = main_area + other_area - inter_area if (main_area + other_area - inter_area) > 0 else 1.0
        iou = inter_area / union_area

        # If another face box has very low overlap with main (IoU < 0.05)
        # and is not tiny (at least 30% of main area), treat as second face.
        if iou < 0.05 and other_area > 0.3 * main_area:
            raise HTTPException(status_code=400, detail="Multiple faces detected")

    face_img = gray[y : y + h, x : x + w]
    return face_img


def _extract_face_embedding(image_array: np.ndarray):
    face_img = _detect_single_face(image_array)
    face_resized = cv2.resize(face_img, (96, 96))
    face_norm = face_resized.astype("float32") / 255.0
    vec = face_norm.flatten()
    norm = np.linalg.norm(vec)
    if norm > 0:
        vec = vec / norm
    embedding = vec.tolist()
    return embedding


def _cosine_similarity(a, b) -> float:
    a = np.array(a, dtype=np.float32)
    b = np.array(b, dtype=np.float32)
    if a.shape != b.shape:
        raise HTTPException(status_code=400, detail="Embedding shapes do not match")
    denom = np.linalg.norm(a) * np.linalg.norm(b)
    if denom == 0:
        return 0.0
    return float(np.dot(a, b) / denom)


@router.post("/register-face")
async def register_face(
    worker_id: int = Form(...),
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    user = db.query(models.User).filter(models.User.id == worker_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Worker not found")
    if user.role != models.UserRole.worker:
        raise HTTPException(status_code=400, detail="User is not a worker")

    file_bytes = await image.read()
    img = _read_image_to_array(file_bytes)
    embedding = _extract_face_embedding(img)

    user.face_embedding = json.dumps(embedding)
    db.commit()

    return {"success": True, "message": "Face registered successfully"}


@router.post("/verify-face")
async def verify_face(
    worker_id: int = Form(...),
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    user = db.query(models.User).filter(models.User.id == worker_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Worker not found")
    if user.role != models.UserRole.worker:
        raise HTTPException(status_code=400, detail="User is not a worker")
    if not user.face_embedding:
        raise HTTPException(status_code=400, detail="No registered face for this worker")

    stored_embedding = json.loads(user.face_embedding)

    file_bytes = await image.read()
    img = _read_image_to_array(file_bytes)
    current_embedding = _extract_face_embedding(img)

    score = _cosine_similarity(stored_embedding, current_embedding)
    threshold = 0.9
    match = score >= threshold

    return {
        "match": match,
        "score": score,
        "threshold": threshold,
    }
