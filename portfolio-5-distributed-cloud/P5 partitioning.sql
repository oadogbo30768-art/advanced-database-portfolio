-- Portfolio 5: Distributed/Cloud demo in single MySQL 8.0 (partitioning = sharding concept)
-- DB: citylight_library. Run top-to-bottom in Workbench.
USE citylight_library;

-- ============ S1: Horizontal partitioning demo (RANGE by year) ============
-- MySQL partitioning requires the partition key in every UNIQUE key, so we demo
-- with a history/archive table (the standard scale-out pattern: hot data + archives).
DROP TABLE IF EXISTS loan_history;
CREATE TABLE loan_history (
  loan_id INT NOT NULL,
  member_id INT NOT NULL,
  book_id INT NOT NULL,
  loan_date DATE NOT NULL,
  return_date DATE NULL,
  PRIMARY KEY (loan_id, loan_date)
) ENGINE=InnoDB
PARTITION BY RANGE (YEAR(loan_date)) (
  PARTITION p2024 VALUES LESS THAN (2025),
  PARTITION p2025 VALUES LESS THAN (2026),
  PARTITION p2026 VALUES LESS THAN (2027),
  PARTITION pmax  VALUES LESS THAN MAXVALUE
);

INSERT INTO loan_history (loan_id, member_id, book_id, loan_date, return_date) VALUES
(101, 1, 1, '2024-03-10', '2024-03-20'),
(102, 2, 4, '2025-06-01', '2025-06-20'),
(103, 3, 5, '2026-01-15', NULL);

-- Partition pruning: this query touches ONLY p2026 (see EXPLAIN PARTITIONS)
EXPLAIN SELECT * FROM loan_history WHERE loan_date BETWEEN '2026-01-01' AND '2026-12-31';
SELECT * FROM loan_history WHERE loan_date BETWEEN '2026-01-01' AND '2026-12-31';

-- Proof partitions exist + row distribution
SELECT PARTITION_NAME, TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'loan_history';

-- ============ S2: Read-replica pattern (logical, single-node demo) ============
-- On one laptop you cannot run a real replica cluster, but you CAN show the
-- read/write split pattern the app would use against a cloud replica:
-- Writes go to primary; heavy reports go to replica (here: same server, pattern documented).
-- A real RDS setup is: RDS MySQL primary (writes) + 1 read replica (Q2/Q3/Q4 reports).
SELECT 'Writes -> primary endpoint; Reports Q2/Q3/Q4 -> replica endpoint' AS replication_pattern;

-- Simulate replica lag check (on real replica: SHOW REPLICA STATUS / Seconds_Behind_Master)
SHOW MASTER STATUS;
