# Portfolio 5: Distributed & Cloud Database Architecture
**Student Name:** Alexis Abakasanga  
**Student ID:** 301905734  
**System:** ShopQuick E-Commerce & Retail Platform  

---

## 1. Cloud Architecture Design (AWS Multi-Region Deployment)
ShopQuick employs a hybrid cloud database deployment across Amazon Web Services (AWS Relational Database Service - Aurora PostgreSQL):
- **Primary Read/Write Cluster:** Deployed in AWS `af-south-1` (Lagos, Nigeria) to ensure low-latency transaction processing for local shoppers.
- **Read Replicas & Disaster Recovery:** Asynchronously replicated to `eu-west-1` (Frankfurt) for failover protection and high-speed data reporting.

## 2. CAP Theorem Trade-Off Analysis
- **Order Checkout & Financial Transactions (CP System):** Prioritizes **Consistency and Partition Tolerance**. During network partitioning between availability zones, the system blocks incomplete transactions to guarantee strict ACID compliance and prevent double-spending.
- **Product Catalog & Customer Reviews (AP System):** Prioritizes **Availability and Partition Tolerance** using MongoDB and Redis. Relies on **BASE eventual consistency** so shoppers can browse products even during minor network disruptions.

## 3. Data Protection & Security (NDPA 2023 Compliance)
- **Encryption Standards:** Data at rest is encrypted using **AES-256**, while data in transit uses **TLS 1.3**.
- **Role-Based Access Control (RBAC):** Restricts database superuser credentials to authorized IT system administrators.
- **Privacy Compliance:** In accordance with the **Nigeria Data Protection Act (NDPA 2023)**, sensitive customer Personally Identifiable Information (PII) is anonymized and stored securely with automated audit logging.
