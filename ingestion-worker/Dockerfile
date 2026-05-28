FROM python:3.12-slim

WORKDIR /app

COPY ingestion-worker/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ingestion-worker/worker.py ./worker.py
COPY api/app ./app

ENV PYTHONUNBUFFERED=1

CMD ["arq", "worker.WorkerSettings"]