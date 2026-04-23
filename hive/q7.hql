-- Q7: severity distribution with percentage share
USE ${hiveconf:DB_NAME};

DROP TABLE IF EXISTS q7_results;

CREATE TABLE q7_results AS
SELECT
  severity,
  COUNT(*)                                                AS accident_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)     AS percentage
FROM us_accidents_part_buck
GROUP BY severity
ORDER BY severity;
