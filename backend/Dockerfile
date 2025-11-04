FROM python:3.12-slim

RUN groupadd -r flask && useradd -r -g flask flask

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN chown -R flask:flask /app

EXPOSE 5000

USER flask
# CMD ["python", "app.py"]
CMD ["gunicorn", "-w5", "-b",  "0.0.0.0:5000", "app:app"]
