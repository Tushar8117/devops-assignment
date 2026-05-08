from fastapi import FastAPI
from datetime import datetime

app = FastAPI()

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api1")
def api1():
    return {
        "message": "Hello from API1",
        "data": [
            {"id": 1, "name": "DevOps Assessment"},
            {"id": 2, "name": "FastAPI Backend"},
            {"id": 3, "name": "Running on Ubuntu EC2"}
        ],
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api2")
def api2():
    return {
        "message": "Internal API2 response",
        "jobs_processed": 42,
        "timestamp": datetime.utcnow().isoformat()
    }
