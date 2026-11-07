-- Portfolio 3: Transactions and Concurrency (MySQL 8.0, InnoDB)
-- DB: citylight_library. Run each block separately in Workbench (not all at once).
USE citylight_library;

-- ============ T1: COMMIT — successful borrow (the happy path) ============
-- Borrow book_id=1 (available) for member_id=2. Must be atomic:
-- stock decrement + loan insert succeed or fail together.
START TRANSACTION;

SELECT book_id, title, available_copies FROM books WHERE book_id = 1 FOR UPDATE;

UPDATE books SET available_copies = available_copies - 1
WHERE book_id = 1 AND available_copies > 0;

INSERT INTO loans (member_id, book_id, staff_id, loan_date, due_date, status)
VALUES (2, 1, 1, CURDATE(), CURDATE() + INTERVAL 14 DAY, 'on_loan');

COMMIT;

-- Verify: available_copies dropped by 1, new loan row exists
SELECT book_id, title, available_copies FROM books WHERE book_id = 1;
SELECT * FROM loans ORDER BY loan_id DESC LIMIT 1;

-- ============ T2: ROLLBACK — failed borrow (no copies left) ============
-- Book 5 has 0 available copies: the transaction must abort cleanly.
START TRANSACTION;

SELECT book_id, title, available_copies FROM books WHERE book_id = 5 FOR UPDATE;

-- This update affects 0 rows (guard clause fails) — detect and roll back
UPDATE books SET available_copies = available_copies - 1
WHERE book_id = 5 AND available_copies > 0;

-- Check ROW_COUNT() in Workbench: 0 means no stock. Roll back explicitly:
ROLLBACK;

-- Verify: nothing changed
SELECT book_id, title, available_copies FROM books WHERE book_id = 5;
SELECT COUNT(*) AS loans_for_book5 FROM loans WHERE book_id = 5;

-- ============ T3: RETURN + FINE — multi-statement atomic transaction ============
-- Returning overdue loan_id=3: set return, compute fine, upsert fine row — all or nothing.
START TRANSACTION;

UPDATE loans
SET return_date = CURDATE(),
    status = 'returned'
WHERE loan_id = 3 AND status = 'overdue';

-- Fine = 100 NGN per overdue day
INSERT INTO fines (loan_id, amount, paid)
VALUES (3, DATEDIFF(CURDATE(), (SELECT due_date FROM (SELECT due_date FROM loans WHERE loan_id = 3) d)) * 100, 0)
ON DUPLICATE KEY UPDATE amount = VALUES(amount);

UPDATE books b
JOIN loans l ON l.book_id = b.book_id
SET b.available_copies = b.available_copies + 1
WHERE l.loan_id = 3;

COMMIT;

SELECT * FROM loans WHERE loan_id = 3;
SELECT * FROM fines WHERE loan_id = 3;

-- ============ T4: ISOLATION DEMO — run in TWO Workbench tabs ============
-- Tab A (Session A):
--   SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
--   START TRANSACTION;
--   SELECT available_copies FROM books WHERE book_id = 4;  -- note value
--   -- (leave transaction OPEN, switch to Tab B)
-- Tab B (Session B):
--   START TRANSACTION;
--   UPDATE books SET available_copies = available_copies - 1 WHERE book_id = 4;
--   COMMIT;
-- Back in Tab A:
--   SELECT available_copies FROM books WHERE book_id = 4;  -- changed under READ COMMITTED
--   COMMIT;
-- Repeat with REPEATABLE READ (MySQL default): the second SELECT in Tab A
-- returns the SAME value (snapshot), proving isolation. Screenshot both.
SELECT @@transaction_isolation AS current_isolation_level;

-- ============ T5: LOST-UPDATE PREVENTION — SELECT ... FOR UPDATE ============
-- Without locking, two librarians issuing the last copy simultaneously
-- both read available_copies=1 and both decrement → negative stock (lost update).
-- Fix: row lock serialises them. Demo pattern (run in two tabs on book_id=3):
--   START TRANSACTION;
--   SELECT available_copies FROM books WHERE book_id = 3 FOR UPDATE;  -- second tab WAITS here
--   UPDATE books SET available_copies = available_copies - 1 WHERE book_id = 3 AND available_copies > 0;
--   INSERT INTO loans (member_id, book_id, staff_id, due_date) VALUES (1, 3, 1, CURDATE() + INTERVAL 14 DAY);
--   COMMIT;  -- waiting tab now proceeds and sees the updated count
-- Evidence: screenshot "Lock wait" in second tab, then correct final count (never negative).
SELECT book_id, title, available_copies FROM books WHERE book_id IN (3, 4);
