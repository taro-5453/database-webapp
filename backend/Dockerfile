# Momo Paradise backend — build from the backend/ directory:
#   docker build -t momo-backend backend/
# Run (config comes from env vars, never baked into the image):
#   docker run --rm -p 8000:8000 \
#     -e MOMO_APP_URL='postgresql://momo_app:...?sslmode=require&channel_binding=disable' \
#     -e FLASK_SECRET_KEY='...' \
#     momo-backend
FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# dependency layer first so code edits don't bust the pip cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY wsgi.py .
COPY app/ app/

# don't run as root inside the container
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

# shell form so ${PORT} expands — Render's Docker runtime injects PORT
CMD gunicorn wsgi:app --bind 0.0.0.0:${PORT:-8000} --workers 2
