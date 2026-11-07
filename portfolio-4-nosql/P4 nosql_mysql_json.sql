-- Portfolio 4: NoSQL-style modelling INSIDE MySQL 8.0 (document + key-value)
-- No MongoDB needed. MySQL JSON covers the "advanced data model" requirement:
-- flexible, schema-less attributes alongside the relational core.
-- DB: citylight_library. Run top-to-bottom.
USE citylight_library;

-- ============ D1: Document model — flexible book metadata as JSON ============
CREATE TABLE IF NOT EXISTS book_profiles (
  book_id INT PRIMARY KEY,
  profile JSON NOT NULL,
  CONSTRAINT fk_profile_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Generated column + index: fast lookup on a JSON path (e.g. all "award winners")
ALTER TABLE book_profiles
  ADD COLUMN IF NOT EXISTS publisher VARCHAR(120)
  GENERATED ALWAYS AS (profile->>'$.publisher') STORED,
  ADD INDEX IF NOT EXISTS idx_profile_publisher (publisher);

TRUNCATE TABLE book_profiles;

-- Same case study, three wildly different shapes in ONE table (this is the NoSQL point:
-- no ALTER TABLE needed when attributes differ per book)
INSERT INTO book_profiles (book_id, profile) VALUES
(1, JSON_OBJECT('publisher','McGraw-Hill','edition',3,'pages',1232,
                'tags', JSON_ARRAY('textbook','database','SQL'),
                'reviews', JSON_ARRAY(JSON_OBJECT('user','Adaeze','rating',5,'text','Our course text')))),
(3, JSON_OBJECT('publisher','Vintage','awards', JSON_ARRAY('Pulitzer Prize 2007'),
                'tags', JSON_ARRAY('fiction','post-apocalyptic'),
                'movie_adaptation', TRUE)),
(4, JSON_OBJECT('publisher','Scholastic','series','Hunger Games #1',
                'tags', JSON_ARRAY('YA','dystopia','bestseller'),
                'stock_by_branch', JSON_OBJECT('abuja', 4, 'lagos', 2)));

-- ============ D2: Document queries (the evidence) ============
-- Extract a field with ->>
SELECT b.title, p.profile->>'$.publisher' AS publisher
FROM book_profiles p JOIN books b ON b.book_id = p.book_id;

-- Multi-valued attribute without a join table: which books are tagged 'database'?
SELECT b.title, p.profile->>'$.tags' AS tags
FROM book_profiles p JOIN books b ON b.book_id = p.book_id
WHERE JSON_CONTAINS(p.profile->'$.tags', '"database"');

-- Nested document access: ratings inside reviews array
SELECT b.title,
       p.profile->'$.reviews[0].rating' AS first_review_rating
FROM book_profiles p JOIN books b ON b.book_id = p.book_id
WHERE p.book_id = 1;

-- Update ONE key inside a document (no schema change, no multi-table write)
UPDATE book_profiles
SET profile = JSON_SET(profile, '$.edition', 4)
WHERE book_id = 1;

-- JSON_TABLE: shred a JSON array into rows (document → relational bridge)
SELECT b.title, j.tag
FROM book_profiles p
JOIN books b ON b.book_id = p.book_id,
JSON_TABLE(p.profile, '$.tags[*]' COLUMNS (tag VARCHAR(60) PATH '$')) AS j
WHERE p.book_id IN (1, 3, 4);

-- ============ D3: Key-value model — app cache / sessions in MySQL ============
-- Same pattern as Redis/DynamoDB: opaque key + value + TTL, for sessions, OTPs, catalogue cache.
CREATE TABLE IF NOT EXISTS kv_store (
  k VARCHAR(200) PRIMARY KEY,
  v JSON NOT NULL,
  expires_at DATETIME NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO kv_store (k, v, expires_at) VALUES
('session:kwena@example.com', JSON_OBJECT('member_id', 2, 'login_at', NOW()), NOW() + INTERVAL 2 HOUR),
('cache:popular_books', JSON_ARRAY('The Hunger Games','Database System Concepts'), NOW() + INTERVAL 15 MINUTE),
('config:loan_days', JSON_OBJECT('days', 14), NULL)
ON DUPLICATE KEY UPDATE v = VALUES(v), expires_at = VALUES(expires_at);

-- Key lookup (O(1) PK access, like any K-V store) + expiry check
SELECT k, v FROM kv_store WHERE k = 'session:kwena@example.com' AND (expires_at IS NULL OR expires_at > NOW());

SELECT 'NoSQL-in-MySQL demo loaded OK' AS result;
