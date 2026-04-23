-- Q1: accident count and average severity per road feature.
USE ${hiveconf:DB_NAME};

DROP TABLE IF EXISTS q1_results;

CREATE TABLE q1_results AS
SELECT 'amenity'         AS road_feature, COUNT(*) AS accident_count, ROUND(AVG(severity), 2) AS avg_severity FROM us_accidents_part_buck WHERE amenity        = true
UNION ALL
SELECT 'bump',                            COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE bump           = true
UNION ALL
SELECT 'crossing',                        COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE crossing       = true
UNION ALL
SELECT 'give_way',                        COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE give_way       = true
UNION ALL
SELECT 'junction',                        COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE junction       = true
UNION ALL
SELECT 'no_exit',                         COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE no_exit        = true
UNION ALL
SELECT 'railway',                         COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE railway        = true
UNION ALL
SELECT 'roundabout',                      COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE roundabout     = true
UNION ALL
SELECT 'station',                         COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE station        = true
UNION ALL
SELECT 'stop',                            COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE stop           = true
UNION ALL
SELECT 'traffic_calming',                 COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE traffic_calming= true
UNION ALL
SELECT 'traffic_signal',                  COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE traffic_signal = true
UNION ALL
SELECT 'turning_loop',                    COUNT(*),                    ROUND(AVG(severity), 2)                FROM us_accidents_part_buck WHERE turning_loop   = true
ORDER BY accident_count DESC;
