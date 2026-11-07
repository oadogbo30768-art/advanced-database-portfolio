Advanced Database Portfolio — Library Management System
Course: MIT 8103 Advanced Database Systems (MIVA Open University, 2026/2027) Case Study: CityLight Public Library — borrow/return, catalogue search, fines. DBMS: MySQL 8.0 only (Workbench / CLI). No MongoDB, no Docker cluster needed. Why this case study: 5 tables, covers everything — design, queries, transactions (borrow/return), NoSQL (MySQL JSON), distributed (replication + partitioning + cloud).

Run everything in order
portfolio-1-database-design/schema.sql — create DB + tables
portfolio-2-query-optimisation/queries.sql — queries + EXPLAIN + indexes
portfolio-3-transactions-concurrency/transactions.sql — commit/rollback/isolation
portfolio-4-nosql/nosql_mysql_json.sql — JSON document/key-value in MySQL
portfolio-5-distributed-cloud/ — partitioning + replication config + cloud deploy notes
Copy screenshots into each folder, push progressively to GitHub, submit final-documentation/ doc on LMS
Repo layout (matches brief's suggested structure)
advanced-database-portfolio/
├── portfolio-1-database-design/
├── portfolio-2-query-optimisation/
├── portfolio-3-transactions-concurrency/
├── portfolio-4-nosql/
├── portfolio-5-distributed-cloud/
├── final-documentation/
└── README.md
Commit progressively — one commit per portfolio — so GitHub history shows continuous work.

AI Use Declaration
Tool: Claude (Anthropic, via Claude Code) — used for scaffolding SQL scripts, README structure, and optimisation explanations.
What for: initial schema, query drafts, transaction examples, JSON examples, replication notes.
Verification: I ran every .sql file in MySQL Workbench myself, captured my own screenshots/outputs, corrected errors, and rewrote the reflection in my own words.
