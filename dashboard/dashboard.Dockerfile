FROM python:3.10-slim

WORKDIR /app

COPY dashboard/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

# expose
EXPOSE 5000

CMD ["python", "app.py"]
