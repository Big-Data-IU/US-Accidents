-- Q5: accident count by hour of day
USE ${hiveconf:DB_NAME};
DROP TABLE IF EXISTS q5_out;
CREATE TABLE IF NOT EXISTS q5_out AS
SELECT 
  HOUR(FROM_UTC_TIMESTAMP(start_time, 'Europe/Moscow')) AS hour,
  COUNT(*) AS accident_count
FROM us_accidents_part_buck
WHERE start_time IS NOT NULL
GROUP BY HOUR(FROM_UTC_TIMESTAMP(start_time, 'Europe/Moscow'))
ORDER BY hour;