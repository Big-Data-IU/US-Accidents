-- Q4: top 10 cities by accident count
USE ${hiveconf:DB_NAME};

DROP TABLE IF EXISTS q4_results;

CREATE TABLE q4_results AS
SELECT
  city,
  state,
  COUNT(*) AS accident_count
FROM us_accidents_part_buck
WHERE city IS NOT NULL
GROUP BY city, state
ORDER BY accident_count DESC
LIMIT 10;
