from sqlalchemy import create_engine, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

SQLALCHEMY_DATABASE_URL = "sqlite:///./siteops.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def _apply_simple_migrations():
    inspector = inspect(engine)
    table_names = inspector.get_table_names()

    if "users" in table_names:
        existing_cols = {col["name"] for col in inspector.get_columns("users")}
        with engine.begin() as conn:
            if "role" not in existing_cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN role VARCHAR"))
            if "phone" not in existing_cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN phone VARCHAR"))
            if "face_embedding" not in existing_cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN face_embedding TEXT"))
            if "profile_photo_url" not in existing_cols:
                conn.execute(
                    text("ALTER TABLE users ADD COLUMN profile_photo_url VARCHAR")
                )

    if "attendance" in table_names:
        existing_cols = {col["name"] for col in inspector.get_columns("attendance")}
        with engine.begin() as conn:
            if "total_wage" not in existing_cols:
                conn.execute(
                    text("ALTER TABLE attendance ADD COLUMN total_wage FLOAT DEFAULT 0")
                )
            if "total_duration_seconds" not in existing_cols:
                conn.execute(
                    text(
                        "ALTER TABLE attendance ADD COLUMN total_duration_seconds INTEGER DEFAULT 0"
                    )
                )


def create_db_and_tables():
    Base.metadata.create_all(bind=engine)
    _apply_simple_migrations()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
