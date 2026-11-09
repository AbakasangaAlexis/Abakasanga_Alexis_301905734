# Portfolio 5: Distributed & Cloud Database Architecture
**Student Name:** Alexis Abakasanga  
**Student ID:** 301905734  
**System:** ShopQuick E-Commerce & Retail Platform  

---

## 1. Cloud Architecture Design (AWS Multi-Region Deployment)
ShopQuick employs a hybrid cloud database deployment across Amazon Web Services (AWS Relational Database Service - Aurora PostgreSQL):
- **Primary Read/Write Cluster:** Deployed in AWS `af-south-1` (Lagos, Nigeria) for low-latency transaction processing.
- **Read Replicas & Disaster Recovery:** Asynchronously replicated to `eu-west-1` (Frankfurt) for failover protection.

## 2. CAP Theorem Trade-Off Analysis
- **Order Checkout & Financial Transactions (CP System):** Prioritizes **Consistency and Partition Tolerance** to guarantee strict ACID compliance.
- **Product Catalog & Customer Reviews (AP System):** Prioritizes **Availability and Partition Tolerance** using MongoDB and Redis with **BASE eventual consistency**.

## 3. Data Protection & Security (NDPA 2023 Compliance)
- **Encryption:** Data at rest is encrypted using **AES-256**, and data in transit uses **TLS 1.3**.
- **NDPA 2023 Compliance:** Personally Identifiable Information (PII) is anonymized with automated audit logging.
