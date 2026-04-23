-- Q1: Accident count and average severity per road feature.
USE ${hiveconf:DB_NAME};

DROP TABLE IF EXISTS q1_results;

CREATE TABLE q1_results AS
SELECT
  t.road_feature,
  COUNT(*)                                                                    AS accident_count,
  ROUND(COUNT(CASE WHEN severity >= 3 THEN 1 END) * 100.0 / COUNT(*), 2)    AS high_severity_pct
FROM us_accidents_part_buck
LATERAL VIEW stack(13,
  'amenity',         amenity,
  'bump',            bump,
  'crossing',        crossing,
  'give_way',        give_way,
  'junction',        junction,
  'no_exit',         no_exit,
  'railway',         railway,
  'roundabout',      roundabout,
  'station',         station,
  'stop',            stop,
  'traffic_calming', traffic_calming,
  'traffic_signal',  traffic_signal,
  'turning_loop',    turning_loop
) t AS road_feature, feature_active
WHERE t.feature_active = true
GROUP BY t.road_feature
ORDER BY accident_count DESC;