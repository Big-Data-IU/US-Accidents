-- Q5: accident count by hour of day
USE ${hiveconf:DB_NAME};

DROP TABLE IF EXISTS q5_results;

CREATE TABLE q5_results AS
SELECT
  HOUR(start_time) AS hour_of_day,
  COUNT(*)         AS accident_count
FROM us_accidents_part_buck
WHERE start_time IS NOT NULL
GROUP BY HOUR(start_time)
ORDER BY hour_of_day;
