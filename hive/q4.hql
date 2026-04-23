-- Q4: top 10 cities by accident count
USE ${hiveconf:DB_NAME};

CREATE TABLE IF NOT EXISTS q4_out AS
SELECT
  city,
  state,
  COUNT(*) AS accident_count
FROM us_accidents_part_buck
WHERE city IS NOT NULL
GROUP BY city, state
ORDER BY accident_count DESC
LIMIT 10;
