from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from .database import create_db_and_tables
from .routers import auth, contractor, worker, inventory, users
from pathlib import Path

app = FastAPI()


@app.on_event("startup")
def on_startup():
    create_db_and_tables()


app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(worker.router, prefix="/api/worker", tags=["worker"])
app.include_router(contractor.router, prefix="/api/contractor", tags=["contractor"])
app.include_router(inventory.router, prefix="/api/inventory", tags=["inventory"])
app.include_router(users.router, prefix="/api/users", tags=["users"])

media_root = Path("media")
media_root.mkdir(parents=True, exist_ok=True)
app.mount("/media", StaticFiles(directory=str(media_root)), name="media")


@app.get("/")
def root():
    return {"message": "API running"}
