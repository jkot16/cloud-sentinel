from flask import Flask, render_template


app = Flask(__name__)

@app.route("/status")
def status():

    events = [
        {"timestamp": "2025-05-02 14:00", "message": "✅ Success – Uploaded"},
        {"timestamp": "2025-05-02 13:00", "message": "❌ Error – S3 denied"},
        {"timestamp": "2025-05-02 14:00", "message": "✅ Success – Uploaded"},
        {"timestamp": "2025-05-02 14:00", "message": "✅ Success – Uploaded"},
        {"timestamp": "2025-05-02 14:00", "message": "✅ Success – Uploaded"},

    ]
    files = ["data_2025-05-02T14.tar.gz", "data_2025-05-02T13.tar.gz"]
    success_count = sum(1 for e in events if e["message"].startswith("✅"))
    failure_count = sum(1 for e in events if e["message"].startswith("❌"))

    return render_template(
        "status.html",
        events=events,
        files=files,
        success_count=success_count,
        failure_count=failure_count
    )

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
