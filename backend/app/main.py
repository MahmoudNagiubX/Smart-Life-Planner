from fastapi import FastAPI

app = FastAPI(
    title="Smart Life Planner API",
    version="0.1.0",
    description="AI-native personal operating system — backend core",
)

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "smart-life-planner-api"}