BEGIN TRANSACTION; -- Start a transaction for improved performance
DROP TABLE benchmark_data;
CREATE TABLE benchmark_data (id INTEGER PRIMARY KEY, data TEXT);

-- Generate numbers from 1 to 100000 using a recursive Common Table Expression (CTE)
WITH RECURSIVE numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n+1 FROM numbers WHERE n < 10000000
)

-- 100000000 => 256 MB
-- Insert data into the benchmark_data table
INSERT INTO benchmark_data (data)
SELECT 'test data ' || n FROM numbers;

SELECT * from benchmark_data;
COMMIT; -- Commit the transaction
