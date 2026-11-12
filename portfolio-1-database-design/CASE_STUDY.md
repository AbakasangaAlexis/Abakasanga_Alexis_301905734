# Case Study Statement

| Item | Description |
|---|---|
| **Organisation / scenario** | Niger Delta Flow Systems Ltd (NDFS), a fictional upstream oil and gas operator in the Niger Delta. |
| **Nature of the system** | A flow station and asset maintenance database. It records where oil and gas are produced, how much is produced each day, what equipment processes it, and how that equipment is maintained. |
| **Users of the database** | Production engineers, maintenance planners, field technicians, store/inventory officers, HSE officers, management. |
| **Major data stored** | Flow stations, wells, equipment, daily production readings, technicians, maintenance work orders, spare parts, HSE incidents. |
| **Key operations supported** | Record daily well production; raise and assign work orders; consume spare parts and keep stock correct; log HSE incidents; report production by station, equipment downtime and maintenance cost. |

**Why this case study.** It has enough structure for design (10 related tables with
one-to-many and many-to-many links), enough volume for optimisation (a daily
production time series), real concurrency risks (two planners consuming the same
spare part), varied data for NoSQL (equipment specifications and sensor telemetry differ by type), and a
natural geographic split for distributed design (stations grouped into regions).

**Disclaimer.** All organisation names, tags, people and figures are fictional.
