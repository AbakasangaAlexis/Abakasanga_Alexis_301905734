# MIVA OPEN UNIVERSITY — POSTGRADUATE SCHOOL OF IT
## MIT8103: ADVANCED DATABASE SYSTEMS CONTINUOUS ASSESSMENT PORTFOLIO

**Student Name:** Alexis Abakasanga  
**Student ID:** 301905734  
**Case Study:** ShopQuick E-Commerce & Retail Platform  

---

### REPOSITORY STRUCTURE

```text
Abakasanga_Alexis_301905734/
├── portfolio-1-database-design/
│   └── schema.sql           (DDL scripts: 5 tables, constraints, PK/FK)
├── portfolio-2-query-optimisation/
│   └── queries.sql          (Analytical SQL queries & EXPLAIN QUERY PLAN)
├── portfolio-3-transactions-concurrency/
│   └── transactions.sql     (BEGIN, COMMIT, ROLLBACK & isolation tests)
├── portfolio-4-nosql/
│   └── nosql-models.json    (MongoDB Document model & JSON schemas)
├── portfolio-5-distributed-cloud/
│   └── cloud_architecture.md(AWS Multi-region, CAP theorem, NDPA 2023)
├── Abakasanga_Alexis_301905734_Report.docx (LMS 2-3 Page Technical Summary)
└── README.md                (Repository Documentation)
```

---

### PORTFOLIO SUMMARY EVIDENCE

1. **Portfolio 1 (Database Design):** Built 5 relational entities (`Customers`, `Products`, `Orders`, `Order_Items`, `Payments`) with primary/foreign key constraints and step-by-step 3NF normalisation.
2. **Portfolio 2 (Query Processing):** Implemented multi-table JOIN aggregations and composite B-Tree indexes (`idx_orders_customer_status`, `idx_products_stock`), eliminating full table scans.
3. **Portfolio 3 (Transactions & Concurrency):** Programmed atomic checkout transactions enforcing ACID properties with `ROLLBACK` recovery and isolation level controls.
4. **Portfolio 4 (NoSQL & Polyglot Persistence):** Designed MongoDB document schemas for flexible product metadata, Redis in-memory key-value caching, and Neo4j Cypher graph recommendation queries.
5. **Portfolio 5 (Distributed & Cloud Architecture):** Formulated AWS multi-region Aurora PostgreSQL replication, CAP theorem (CP vs AP) trade-offs, and NDPA 2023 security encryption compliance.

---

### AI USE DECLARATION & AUDIT
In accordance with Miva Open University academic integrity policy, Gemini Notebook was utilized as an auxiliary tool for document structure, markdown layout, and test execution. All database schemas, SQL queries, transaction scripts, and architectural models were reviewed, verified, and audited by Alexis Abakasanga.
