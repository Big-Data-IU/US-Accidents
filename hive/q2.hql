-- Q2: Average accident severity and count by wind speed range.
USE ${hiveconf:DB_NAME};

DROP TABLE IF EXISTS q2_results;

CREATE TABLE q2_results AS
SELECT
  bucket,
  COUNT(*)                                                                 AS accident_count,
  ROUND(COUNT(CASE WHEN severity >= 3 THEN 1 END) * 100.0 / COUNT(*), 2) AS high_severity_pct
FROM (
  SELECT
    CASE
      WHEN wind_speed_mph <  5  THEN '1: 0-5 mph (Calm)'
      WHEN wind_speed_mph < 15  THEN '2: 5-15 mph (Light)'
      WHEN wind_speed_mph < 25  THEN '3: 15-25 mph (Moderate)'
      WHEN wind_speed_mph < 35  THEN '4: 25-35 mph (Strong)'
      ELSE                           '5: 35+ mph (Very Strong)'
    END AS bucket,
    severity
  FROM us_accidents_part_buck
  WHERE wind_speed_mph IS NOT NULL
) t
GROUP BY bucket
ORDER BY bucket;