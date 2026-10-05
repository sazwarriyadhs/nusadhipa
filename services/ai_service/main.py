"""
Nusa Dhipa AI Service
Universal AI Copilot Engine
"""

from fastapi import FastAPI

from api.routes import router


app = FastAPI(
    title="Nusa Dhipa AI Service",
    version="2.0.0",
    description="Universal AI Copilot Engine for Nusa Dhipa Business OS",
)

app.include_router(router)


@app.get("/health")
def health():
    return {
        "service": "nusa-dhipa-ai",
        "status": "ok",
        "version": "2.0.0",
    }
