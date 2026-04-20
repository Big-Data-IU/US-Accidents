COPY us_accidents (
    id, source, severity, start_time, end_time, start_lat, start_lng, end_lat, end_lng,
    distance_mi, description, street, city, county, state, zipcode, country, timezone,
    airport_code, weather_timestamp, temperature_f, wind_chill_f, humidity_pct, pressure_in,
    visibility_mi, wind_direction, wind_speed_mph, precipitation_in, weather_condition,
    amenity, bump, crossing, give_way, junction, no_exit, railway, roundabout, station, stop,
    traffic_calming, traffic_signal, turning_loop, sunrise_sunset, civil_twilight,
    nautical_twilight, astronomical_twilight
)
FROM STDIN
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    NULL '',
    QUOTE '"'
);
