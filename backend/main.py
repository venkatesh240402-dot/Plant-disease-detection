from fastapi import FastAPI
from backend.routers import detect

app = FastAPI(title="AgroScan API")

app.include_router(detect.router, prefix="/api", tags=["Detection"])

@app.get("/")
def read_root():
    return {"message": "AgroScan API is running"}
