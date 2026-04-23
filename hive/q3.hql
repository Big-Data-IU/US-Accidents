-- Q3: High-severity accident rate by visibility range.
USE ${hiveconf:DB_NAME};

CREATE TABLE IF NOT EXISTS q3_out AS
SELECT
  bucket,
  COUNT(*)                                                                 AS accident_count,
  ROUND(COUNT(CASE WHEN severity >= 3 THEN 1 END) * 100.0 / COUNT(*), 2) AS high_severity_pct
FROM (
  SELECT
    CASE
      WHEN visibility_mi <  1  THEN '1: 0-1 mi (Near Zero)'
      WHEN visibility_mi <  3  THEN '2: 1-3 mi (Low)'
      WHEN visibility_mi <  7  THEN '3: 3-7 mi (Moderate)'
      WHEN visibility_mi < 10  THEN '4: 7-10 mi (Good)'
      ELSE                          '5: 10+ mi (Clear)'
    END AS bucket,
    severity
  FROM us_accidents_part_buck
  WHERE visibility_mi IS NOT NULL
) t
GROUP BY bucket
ORDER BY bucket;
