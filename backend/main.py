from fastapi import FastAPI
app = FastAPI(title="AgroScan API")
@app.get("/")
def read_root():
    return {"message": "AgroScan API is running"}
