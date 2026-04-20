-- Row count: quick check that the bulk load completed.
SELECT COUNT(*) AS accidents_count FROM us_accidents;

-- Sample rows: sanity check of a few columns.
SELECT id, source, severity, start_time, city, state
FROM us_accidents
ORDER BY start_time
LIMIT 5;
