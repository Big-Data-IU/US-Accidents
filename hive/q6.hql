-- Q6: Top 15 weather conditions during accidents with high severity rates.
USE ${hiveconf:DB_NAME};

CREATE TABLE IF NOT EXISTS q6_out AS
SELECT
  weather_condition,
  COUNT(*)                                                                 AS accident_count,
  ROUND(COUNT(CASE WHEN severity >= 3 THEN 1 END) * 100.0 / COUNT(*), 2) AS high_severity_pct
FROM us_accidents_part_buck
WHERE weather_condition IS NOT NULL
GROUP BY weather_condition
HAVING COUNT(*) > 100
ORDER BY accident_count DESC
LIMIT 15;
