PRAGMA synchronous=OFF;
PRAGMA journal_mode=MEMORY;
--PRAGMA page_size=1024;

-- PRAGMA count_changes=OFF;
-- PRAGMA temp_store=MEMORY;

CREATE TABLE large_table (
    id INTEGER PRIMARY KEY,
    data1 TEXT,
    data2 TEXT,
    data3 TEXT
);

BEGIN TRANSACTION;
WITH RECURSIVE
cnt(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM cnt
    WHERE x < 5000000
)
INSERT INTO large_table (data1, data2, data3)
SELECT
    randomblob(250),
    randomblob(250),
    randomblob(250)
FROM cnt;
COMMIT;
