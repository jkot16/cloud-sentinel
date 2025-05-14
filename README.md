# 🚧 Cloud Sentinel

Cloud Sentinel is a cloud-native backup monitoring system built with Flask, Docker, and AWS services.  
It provides a visual dashboard for tracking EC2-to-S3 backups, integrated with CloudWatch Logs and Slack alerting.

This project is currently under active development.

### 🔧 Key features to be implemented:
- Automated EC2 → S3 backups with timestamped archives
- Slack notifications on success/failure
- Centralized logging with CloudWatch Logs
- Scheduled execution via EventBridge and SSM Agent
- Secure IAM configuration (least privilege)
- Containerized architecture (Docker)
- Full CI/CD pipeline (GitHub Actions)
- End-to-end testing flow

---

### Why this project matters

This project simulates a real-world DevOps scenario where secure, automated backups and observability are critical for cloud infrastructure.  
It demonstrates key DevOps practices such as:

- Automating cloud workflows with Bash, AWS CLI, and SSM
- Applying monitoring and alerting with CloudWatch and Slack
- Building a CI/CD pipeline for Dockerized components
- Designing systems with least privilege access (IAM policies)
- Visualizing system status through a custom Flask dashboard

By combining cloud-native tooling, infrastructure automation, and containerization, Cloud Sentinel showcases a practical, production-like DevOps workflow — built from scratch.
