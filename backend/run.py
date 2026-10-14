import os
import uvicorn

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    is_dev = os.getenv("ENVIRONMENT", "development").lower() == "development"
    reload_enabled = os.getenv("RELOAD", "true" if is_dev else "false").lower() in ("true", "1")
    
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=reload_enabled)

