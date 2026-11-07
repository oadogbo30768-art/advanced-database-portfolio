# Portfolio 3 — Transactions and Concurrency

All scripts in `transactions.sql`. Run each block **separately** in MySQL Workbench (T4/T5 need two tabs open).

## What to run and screenshot
1. **T1 COMMIT (borrow):** `START TRANSACTION → SELECT ... FOR UPDATE → UPDATE stock → INSERT loan → COMMIT`. Screenshot: stock drops by 1 AND new loan row. Proves atomicity — both succeed together.
2. **T2 ROLLBACK (no stock):** book 5 has 0 copies → `UPDATE` affects 0 rows → `ROLLBACK`. Screenshot: `SELECT` shows stock still 0, no new loan. Proves failed work leaves no partial writes.
3. **T3 RETURN + FINE:** one transaction does `UPDATE loans → INSERT/UPDATE fines → UPDATE books`. Screenshot all three tables after COMMIT. If any statement failed, nothing would persist.
4. **T4 Isolation (two tabs):** follow the Tab A/Tab B script in the SQL comments. Run once under `READ COMMITTED`, once under `REPEATABLE READ` (MySQL default). Screenshot both second-SELECTs:
   - READ COMMITTED: Tab A sees the new value (no repeatable snapshot).
   - REPEATABLE READ: Tab A sees the OLD value (snapshot isolation). State which you observed.
5. **T5 Lost-update prevention:** two tabs race for the last copy of book 3 with `SELECT ... FOR UPDATE`. Screenshot: second tab waits ("lock wait"), final `available_copies` never goes negative. Without `FOR UPDATE`, both could read 1 and both decrement → -1 (lost update).

## Concurrency issue + control
- **Issue demonstrated:** lost update on `books.available_copies` when two librarians issue the last copy at the same time, plus non-repeatable reads under weak isolation.
- **Controls used:** InnoDB row-level locks via `SELECT ... FOR UPDATE`, atomic `UPDATE ... WHERE available_copies > 0` guard, `START TRANSACTION/COMMIT/ROLLBACK`, and `REPEATABLE READ` default. ACID: Atomicity (T1–T3), Consistency (CHECK + FKs), Isolation (T4), Durability (InnoDB commit).
- **Why InnoDB:** supports transactions + FKs + row locks (MyISAM would not).

## Checklist
- [ ] T1 + T2 + T3 outputs screenshotted
- [ ] T4 two-isolation comparison screenshots
- [ ] T5 lock-wait + final count screenshot
- [ ] `SELECT @@transaction_isolation;` output captured
