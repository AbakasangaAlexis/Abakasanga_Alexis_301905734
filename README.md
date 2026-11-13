# MIT 8103 Advanced Database Systems: Individual Practical Portfolio

**Student:** Alexis John Abakasanga (Student ID 301905734)
**Programme:** MIT, Master of Information Technology, 2026/2027 First Semester Continuous Assessment

## Selected case study
**Niger Delta Flow Systems Ltd (NDFS)**, a fictional upstream oil and gas operator. The system is a **flow station and
asset maintenance database**: wells, flow stations, equipment, daily production readings, maintenance work orders,
technicians, spare parts and HSE incidents. Full statement: [`portfolio-1-database-design/CASE_STUDY.md`](portfolio-1-database-design/CASE_STUDY.md).
The same case study is used in all five portfolios.

## Technology
PostgreSQL 18.6 on Windows with psql and pgAdmin 4 (relational, Portfolios 1 to 3); MongoDB Atlas free tier (M0), MongoDB 8.0.37, AWS Paris, with mongosh 2.14.2 (NoSQL and cloud, Portfolios 4 and 5); Git and GitHub; Mermaid (ER and architecture diagrams).

## Repository map
| Folder | Portfolio | Main contents |
|---|---|---|
| [`portfolio-1-database-design`](portfolio-1-database-design) | Database design and modelling | ER diagram, DDL with keys and constraints, sample data, constraint tests, normalisation explanation |
| [`portfolio-2-query-optimisation`](portfolio-2-query-optimisation) | Query processing and optimisation | Bulk data, 7 queries, execution plans before/after, indexes, performance analysis |
| [`portfolio-3-transactions-concurrency`](portfolio-3-transactions-concurrency) | Transactions and concurrency | Commit/rollback/savepoint, lost update and fixes, isolation levels, deadlock, safe function |
| [`portfolio-4-nosql`](portfolio-4-nosql) | NoSQL and advanced data models | MongoDB document, embedded and time-series models, queries, indexes and explain |
| [`portfolio-5-distributed-cloud`](portfolio-5-distributed-cloud) | Distributed and cloud databases | Architecture, fragmentation, replication, CAP, Atlas replica set evidence, sharding design |

## How to reproduce everything
1. Install PostgreSQL 18 (with pgAdmin) and MongoDB `mongosh`; create a free MongoDB Atlas cluster.
2. PostgreSQL, in this order:
   ```
   psql -U postgres -f portfolio-1-database-design/00_create_database.sql
   psql -U postgres -d ndfs_db -f portfolio-1-database-design/01_schema.sql
   psql -U postgres -d ndfs_db -f portfolio-1-database-design/02_sample_data.sql
   psql -U postgres -d ndfs_db -f portfolio-1-database-design/03_constraint_tests.sql
   psql -U postgres -d ndfs_db -f portfolio-2-query-optimisation/01_bulk_data.sql
   ```
   then the numbered scripts in Portfolios 2 and 3 as described in their READMEs.
3. MongoDB: `mongosh "<connection string>" --apiVersion 1 --username <user> --password <password> --file portfolio-4-nosql/01_setup_collections.js`, then 02, 03, 04, and scripts 01 and 02 in Portfolio 5. (Credentials are never stored in this repository.)

## How each portfolio was implemented and tested
Each portfolio folder has its own README with the design decisions, the run order, **the results I observed on my machine**
and an `evidence/` folder holding my screenshots and the raw text outputs (execution plans, query results, mongosh output).

| Portfolio | Key evidence from my runs |
|---|---|
| 1 | 10 tables created; 8 deliberate invalid statements all rejected by constraints |
| 2 | Q5 open backlog 169.8 ms -> 0.09 ms with a partial index; Q4 178.2 ms -> 2.3 ms; PostgreSQL 18 skip scan observed before indexing |
| 3 | Lost update reproduced and fixed two ways; non-repeatable read, snapshot conflict, serializable write skew and deadlock all demonstrated in two sessions |
| 4 | 20,000 embedded work orders, time-series telemetry; COLLSCAN of 20,000 documents -> IXSCAN of 517 |
| 5 | Atlas 3-member replica set (1 primary, 2 secondaries); majority vs w:1 writes and secondary reads |

## Academic integrity and AI use declaration
See [`Abakasanga_Alexis_301905734_AI_Declaration.md`](Abakasanga_Alexis_301905734_AI_Declaration.md).

## References
- Silberschatz, A., Korth, H. F. and Sudarshan, S. (2020) *Database System Concepts*. 7th edn. McGraw-Hill.
- Özsu, M. T. and Valduriez, P. (2020) *Principles of Distributed Database Systems*. 4th edn. Springer.
- Cattell, R. (2011) 'Scalable SQL and NoSQL data stores', *ACM SIGMOD Record*, 39(4), pp. 12-27.
- Grolinger, K. et al. (2013) 'Data management in cloud environments: NoSQL and NewSQL data stores', *Journal of Cloud Computing*, 2(22).
- PostgreSQL Global Development Group (2025) *PostgreSQL 18 Documentation*. https://www.postgresql.org/docs/18/
- MongoDB, Inc. (2025) *MongoDB Manual (version 8.0)*. https://www.mongodb.com/docs/manual/
- MIT 8103 lecture materials, Sessions 1 to 3 (MIVA Open University, 2026).
