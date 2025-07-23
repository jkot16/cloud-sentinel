from flask import Flask, render_template
import boto3
from datetime import datetime, timezone
import os
import pytz
app = Flask(__name__)

LOG_GROUP = os.getenv("LOG_GROUP", "cloud-sentinel-backup")
LOG_STREAM = os.getenv("LOG_STREAM", "main-backup-log")
REGION = os.getenv("AWS_REGION", "eu-central-1")

logs_client = boto3.client("logs", region_name=REGION)

@app.route("/status")
def status():
    events = []
    files = []

    try:
        response = logs_client.get_log_events(
            logGroupName=LOG_GROUP,
            logStreamName=LOG_STREAM,
            startFromHead=False,
            limit=10
        )

        local_tz = pytz.timezone("Europe/Warsaw")
        for e in response.get("events", []):
            timestamp = datetime.fromtimestamp(e["timestamp"] / 1000, tz=timezone.utc).astimezone(local_tz)
            message = e["message"]

            events.append({
                "timestamp": timestamp.strftime("%Y-%m-%d %H:%M"),
                "message": message.strip()
            })


            if "Backup successful" in message and ".tar.gz" in message:
                filename = message.split("Backup successful: ")[-1].strip()
                files.append(filename)


        today = datetime.now(local_tz).date()

        success_count = 0
        failure_count = 0

        for e in events:
            event_date = datetime.strptime(e["timestamp"], "%Y-%m-%d %H:%M").date()
            if event_date == today:
                if "Backup successful" in e["message"]:
                    success_count += 1
                elif "Backup failed" in e["message"]:
                    failure_count += 1


    except Exception as e:
        print(f"[ERROR] Failed to fetch logs: {e}")
        events = []
        files = []
        success_count = 0
        failure_count = 0

    return render_template(
        "status.html",
        events=events[::-1],
        files=files[-5:],
        success_count=success_count,
        failure_count=failure_count
    )

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
