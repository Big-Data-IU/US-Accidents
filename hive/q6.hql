-- Q6: top 15 weather conditions during accidents with average severity
USE ${hiveconf:DB_NAME};

DROP TABLE IF EXISTS q6_results;

CREATE TABLE q6_results AS
SELECT
  weather_condition,
  COUNT(*)              AS accident_count,
  ROUND(AVG(severity), 2) AS avg_severity
FROM us_accidents_part_buck
WHERE weather_condition IS NOT NULL
GROUP BY weather_condition
HAVING COUNT(*) > 100
ORDER BY accident_count DESC
LIMIT 15;
