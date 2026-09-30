# Build the React frontend first, then run the FastAPI backend in the same
# Render service. This keeps API, Seedr sessions, media streaming and UI on
# one origin, so browser credentials/cookies work without Vercel-to-Render
# cross-origin issues.
FROM node:22-bookworm-slim AS frontend-build

WORKDIR /frontend
COPY frontend/package.json ./package.json
RUN npm install
COPY frontend/ ./
RUN npm run build

FROM python:3.12-slim

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends aria2 ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ ./
COPY --from=frontend-build /frontend/dist ./frontend/dist

ENV PYTHONUNBUFFERED=1
ENV FRONTEND_DIST=/app/frontend/dist

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-10000}"]
