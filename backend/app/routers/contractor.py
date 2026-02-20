from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .. import schemas, models
from ..database import get_db
from ..utils.dependencies import get_current_user
from datetime import datetime

router = APIRouter()

@router.get("/dashboard")
def get_contractor_dashboard(current_user: models.User = Depends(get_current_user)):
    # This is a placeholder. A real implementation would return more dashboard-specific data
    return {"message": f"Welcome contractor {current_user.username}"}

@router.get("/workers", response_model=list[schemas.User])
def get_workers(site_id: int | None = None, status: str | None = None, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    query = db.query(models.User).filter(models.User.role == models.UserRole.worker)
    if site_id is not None:
        worker_ids = (
            db.query(models.SiteWorker.worker_id)
            .filter(
                models.SiteWorker.site_id == site_id,
            )
            .subquery()
        )
        query = query.filter(models.User.id.in_(worker_ids))
    return query.all()

@router.get("/sites", response_model=list[schemas.Site])
def get_sites(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    return db.query(models.Site).filter(models.Site.contractor_id == current_user.id).all()

@router.post("/sites", response_model=schemas.Site)
def create_site(site: schemas.SiteCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    db_site = models.Site(**site.dict(), contractor_id=current_user.id)
    db.add(db_site)
    db.commit()
    db.refresh(db_site)
    return db_site


@router.get("/sites/{site_id}", response_model=schemas.Site)
def get_site_detail(site_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    db_site = (
        db.query(models.Site)
        .filter(models.Site.id == site_id, models.Site.contractor_id == current_user.id)
        .first()
    )
    if not db_site:
        raise HTTPException(status_code=404, detail="Site not found")
    return db_site


@router.post("/sites/{site_id}/add-worker")
def add_worker_to_site(
    site_id: int,
    worker_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    site = (
        db.query(models.Site)
        .filter(models.Site.id == site_id, models.Site.contractor_id == current_user.id)
        .first()
    )
    if not site:
        raise HTTPException(status_code=404, detail="Site not found")
    worker = db.query(models.User).filter(models.User.id == worker_id).first()
    if not worker or worker.role != models.UserRole.worker:
        raise HTTPException(status_code=400, detail="Invalid worker")
    existing = (
        db.query(models.SiteWorker)
        .filter(
            models.SiteWorker.site_id == site_id,
            models.SiteWorker.worker_id == worker_id,
        )
        .first()
    )
    if existing:
        return {"message": "Worker already assigned"}
    mapping = models.SiteWorker(site_id=site_id, worker_id=worker_id)
    db.add(mapping)
    db.commit()
    return {"message": "Worker assigned successfully"}


@router.get("/sites/{site_id}/workers", response_model=list[schemas.User])
def get_site_workers(
    site_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    worker_ids = (
        db.query(models.SiteWorker.worker_id)
        .filter(models.SiteWorker.site_id == site_id)
        .subquery()
    )
    workers = db.query(models.User).filter(models.User.id.in_(worker_ids)).all()
    return workers

@router.get("/alerts", response_model=list[schemas.Alert])
def get_alerts(site_id: int | None = None, severity: str | None = None, is_resolved: bool | None = None, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    query = db.query(models.Alert)
    # In a real app, you'd filter by site, severity, and resolution status
    return query.all()

@router.post("/alerts", response_model=schemas.Alert)
def create_alert(alert: schemas.AlertCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    db_alert = models.Alert(**alert.dict())
    db.add(db_alert)
    db.commit()
    db.refresh(db_alert)
    return db_alert

@router.patch("/alerts/{alert_id}/resolve", response_model=schemas.Alert)
def resolve_alert(alert_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    db_alert = db.query(models.Alert).filter(models.Alert.id == alert_id).first()
    if not db_alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    db_alert.is_resolved = True
    db.commit()
    db.refresh(db_alert)
    return db_alert

@router.get("/attendance/site-live-wages")
def get_site_live_wages(
    site_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if current_user.role != models.UserRole.contractor:
        raise HTTPException(status_code=403, detail="Not authorized")
    query = (
        db.query(models.Attendance)
        .join(models.Site, models.Attendance.site_id == models.Site.id)
        .join(models.User, models.Attendance.user_id == models.User.id)
        .filter(models.Site.contractor_id == current_user.id)
    )
    if site_id is not None:
        query = query.filter(models.Attendance.site_id == site_id)
    records = query.all()
    now = datetime.utcnow()
    results: list[dict] = []
    for rec in records:
        if rec.check_out is None:
            total_seconds = int((now - rec.check_in).total_seconds())
            intervals = total_seconds // 15
            wage = float(intervals * 100)
            status = "checked_in"
        else:
            if rec.total_duration_seconds and rec.total_wage:
                total_seconds = rec.total_duration_seconds
                wage = rec.total_wage
            else:
                total_seconds = int((rec.check_out - rec.check_in).total_seconds())
                intervals = total_seconds // 15
                wage = float(intervals * 100)
            status = "checked_out"
        results.append(
            {
                "attendance_id": rec.id,
                "worker_id": rec.user_id,
                "worker_name": rec.user.full_name or rec.user.username,
                "worker_photo": rec.user.profile_photo_url,
                "site_id": rec.site_id,
                "site_name": rec.site.name,
                "check_in_time": rec.check_in,
                "check_out_time": rec.check_out,
                "current_wage": wage,
                "total_duration_seconds": total_seconds,
                "status": status,
            }
        )
    return results
