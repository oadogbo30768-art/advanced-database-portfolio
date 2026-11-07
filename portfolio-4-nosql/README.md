# Portfolio 4 — NoSQL and Advanced Data Models

Everything runs in MySQL 8.0 — `nosql_mysql_json.sql`. No MongoDB/Redis to install; MySQL's `JSON` type + `kv_store` table demonstrate the **document** and **key-value** models on the same library case study.

## Mapping
- **Relational core (unchanged):** `members, books, loans, fines` — strong consistency for borrowing, stock, fines.
- **Document add-on (`book_profiles.profile` JSON):** publisher, edition, tags, awards, reviews, per-branch stock — attributes that differ per book and would need constant `ALTER TABLE` or sparse columns relationally. Three sample books have deliberately different shapes to prove flexibility.
- **Key-value add-on (`kv_store`):** sessions, catalogue cache, config — opaque key → JSON value + TTL, the Redis/DynamoDB pattern.

## Queries that prove it
1. `profile->>'$.publisher'` — field extraction without joins.
2. `JSON_CONTAINS(... tags ...)` — multi-valued search with no bridge table.
3. `JSON_SET` edition update — schema-less evolution (no migration).
4. `JSON_TABLE(... tags ...)` — shredding documents back to rows (polyglot bridge).
5. `kv_store` key lookup with expiry — K-V access pattern.

## Suitability argument
- Use **relational** where integrity matters (loans, stock, fines: FKs + ACID).
- Use **document (JSON)** where shape varies and reads are whole-object (book metadata, reviews, tags) — avoids 5 extra sparse tables and lets librarians add attributes without a DBA migration.
- Use **key-value** for ephemeral, high-read data (sessions, cache) where the app always accesses by key and never joins.
- Trade-offs: JSON is harder to constrain (no CHECK per key, weaker typing), slower for aggregations across millions of docs, and generated-column indexes only cover known paths — so keep money/stock relational and metadata flexible. A full MongoDB would scale documents independently, but for this portfolio MySQL JSON proves the modelling concept with zero extra tooling.

## Checklist
- [ ] `nosql_mysql_json.sql` executed green
- [ ] 5 query result screenshots
- [ ] `SHOW CREATE TABLE book_profiles;` screenshot (generated column + index visible)
