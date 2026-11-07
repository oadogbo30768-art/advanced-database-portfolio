# Portfolio 2 — Query Processing and Optimisation (7 marks)

All queries are in `queries.sql`. Run in MySQL Workbench, screenshot each result grid + each EXPLAIN.

## What each query proves
1. **Q1 catalogue search** — selective filter (`category`, `available_copies`, keyword). Uses `idx_books_title` / category path.
2. **Q2 overdue report** — 3-table join + `DATEDIFF` fine estimate. The librarian's daily report.
3. **Q3 member history** — `LEFT JOIN` + `GROUP BY` + conditional `SUM` (transcript equivalent: total loans, overdue count, unpaid fines).
4. **Q4 popularity ranking** — aggregation + `RANK()` window function (advanced concept credit).
5. **Q5 never-borrowed books** — `NOT EXISTS` anti-join (optimiser handles better than `NOT IN` with NULLs).

## Optimisation evidence (the marks live here)
1. Run the first `EXPLAIN FORMAT=TREE` **before** creating `idx_loans_member_status` → screenshot (likely full scan / single-column index only).
2. `CREATE INDEX idx_loans_member_status ON loans(member_id, status)` → screenshot Output pane ("0 rows affected").
3. Re-run the second `EXPLAIN FORMAT=TREE` → screenshot showing index range scan on `idx_loans_member_status`.
4. Run `EXPLAIN ANALYZE` on the overdue join → screenshot actual time (e.g. `actual time=0.05..0.12`).
5. `SHOW INDEX FROM books; SHOW INDEX FROM loans;` → screenshot.

## 5-line performance analysis (paste into LMS doc, in your own words)
- The issue-desk lookup (`member_id + status`) went from full-table/weak-index access to a composite index range scan.
- Q2/Q3 join cost is dominated by `loans.status` filtering; `idx_loans_status` + `idx_loans_member_status` keep it index-assisted even as loans grow.
- `Q5 NOT EXISTS` avoids `NOT IN` NULL pitfalls and lets the optimiser use `idx_loans_book`.
- Window function in Q4 costs one sort pass; acceptable for a popularity report run on demand, not per transaction.
- Trade-off: 6 indexes speed reads but slow writes slightly — fine for a read-heavy library catalogue.

## Checklist
- [ ] All 5 queries executed, result grids screenshotted
- [ ] EXPLAIN before/after screenshots + `EXPLAIN ANALYZE` output
- [ ] `SHOW INDEX` screenshot
