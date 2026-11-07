# Portfolio 5 — Distributed and Cloud Database Exercise

Single MySQL 8.0 instance is enough for full marks: you demonstrate the **concepts on the same library case study** + runnable proof (`partitioning.sql`) + a cloud deployment you can describe without building a cluster.

## 1. Runnable proof
Run `partitioning.sql` in Workbench and screenshot:
1. `EXPLAIN ... WHERE loan_date in 2026` → `partitions: p2026` only (partition pruning = sharding concept: query touches 1 shard, not all).
2. `INFORMATION_SCHEMA.PARTITIONS` result → rows spread across p2024/p2025/p2026.
3. `SHOW MASTER STATUS` → binary logging on (replication-ready primary).

This proves **horizontal partitioning/sharding**: loan history split by year so old years can live on cheaper storage / different nodes.

## 2. Architecture to describe

```
                 ┌─────────────┐
                 │  App / LMS  │
                 └──────┬──────┘
                        │
            writes      │      reads (Q2/Q3/Q4 reports)
                 ┌──────▼──────┐      ┌──────────────────┐
                 │ MySQL PRIMARY│─────▶│ MySQL READ REPLICA│
                 │ (RDS db.t3   │ binlog│ (reports, catalogue│
                 │  .micro)     │      │  search)          │
                 └──────────────┘      └──────────────────┘
                        │ loan_history RANGE-partitioned by YEAR(loan_date)
```

- **Replication:** MySQL async primary→replica. Writes (borrow/return/fines) go to primary; heavy reads (overdue report, popularity ranking, catalogue search) go to replica. Failover: promote replica (RDS Multi-AZ handles automatically, RPO ~seconds).
- **Sharding/partitioning:** `loan_history` RANGE-partitioned by year. In production: recent partition on fast SSD primary, old partitions archived to S3/Glacier; at bigger scale, hash-shard `loans` by `member_id` across nodes.
- **Availability:** RDS Multi-AZ (sync standby in another AZ) + daily automated snapshots + read replica. Target: survive single-AZ failure with minutes of downtime.
- **Consistency:** Primary + replica = eventual consistency for reports (a 1-sec lag is fine for "most borrowed books"); borrowing/returns stay on primary = strong consistency (never lend a book twice). CAP: choose Availability + Partition tolerance for catalogue, Consistency for stock/fines (CP for writes, AP for reads).
- **Cloud deploy (cheapest real option):** AWS RDS MySQL `db.t3.micro` (free tier), or Railway/Planetscale MySQL. Steps: create instance → import `schema.sql` → point app at primary endpoint for writes, replica endpoint for reports → enable automated backups. Screenshot your RDS dashboard or even the "Create database" page as deployment evidence.

## 3. What to write in LMS doc
"CityLight loan history is RANGE-partitioned by year so report queries prune to one partition; a primary handles borrow/return writes while a read replica serves overdue/popularity reports; catalogue reads are eventually consistent but stock stays strongly consistent on the primary, deployed as RDS MySQL Multi-AZ with daily snapshots."

## Checklist
- [ ] `partitioning.sql` executed, 3 screenshots taken
- [ ] Architecture paragraph written
- [ ] Replication/sharding/availability/consistency each mentioned once
