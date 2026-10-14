#!/bin/sh
set -e

# ==============================================================================
# Container Entrypoint for Local Skill Exchange Backend
# ==============================================================================

# Optional automated database seeding on fresh deployment (set INIT_SEEDS=true in Railway variables)
if [ "$INIT_SEEDS" = "true" ] || [ "$INIT_SEEDS" = "1" ]; then
    echo "[Entrypoint] INIT_SEEDS is enabled. Seeding skills catalog and flagship learning paths..."
    python scripts/import_skills.py || echo "[Entrypoint] Warning: import_skills.py encountered a non-fatal warning"
    python scripts/seed_curated_learning.py || echo "[Entrypoint] Warning: seed_curated_learning.py encountered a non-fatal warning"
    echo "[Entrypoint] Database seeding routine complete."
fi

# Launch FastAPI application
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}" --workers 2
