from fastapi import FastAPI
from app.api.v1.router import router

app = FastAPI(
    title="Smart Life Planner API",
    version="0.1.0",
    description="AI-native personal operating system — backend core",
)

app.include_router(router)

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "smart-life-planner-api"}