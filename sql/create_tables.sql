START TRANSACTION;

DROP TABLE IF EXISTS us_accidents CASCADE;

CREATE TABLE IF NOT EXISTS us_accidents (
    id TEXT PRIMARY KEY,
    source TEXT NOT NULL,
    severity SMALLINT NOT NULL CHECK (severity BETWEEN 1 AND 4),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    start_lat DOUBLE PRECISION NOT NULL,
    start_lng DOUBLE PRECISION NOT NULL,
    end_lat DOUBLE PRECISION,
    end_lng DOUBLE PRECISION,
    distance_mi DOUBLE PRECISION,
    description TEXT,
    street TEXT,
    city TEXT,
    county TEXT,
    state VARCHAR(2),
    zipcode TEXT,
    country VARCHAR(2),
    timezone TEXT,
    airport_code TEXT,
    weather_timestamp TIMESTAMP,
    temperature_f DOUBLE PRECISION,
    wind_chill_f DOUBLE PRECISION,
    humidity_pct DOUBLE PRECISION,
    pressure_in DOUBLE PRECISION,
    visibility_mi DOUBLE PRECISION,
    wind_direction TEXT,
    wind_speed_mph DOUBLE PRECISION,
    precipitation_in DOUBLE PRECISION,
    weather_condition TEXT,
    amenity BOOLEAN,
    bump BOOLEAN,
    crossing BOOLEAN,
    give_way BOOLEAN,
    junction BOOLEAN,
    no_exit BOOLEAN,
    railway BOOLEAN,
    roundabout BOOLEAN,
    station BOOLEAN,
    stop BOOLEAN,
    traffic_calming BOOLEAN,
    traffic_signal BOOLEAN,
    turning_loop BOOLEAN,
    sunrise_sunset TEXT,
    civil_twilight TEXT,
    nautical_twilight TEXT,
    astronomical_twilight TEXT
);

CREATE INDEX IF NOT EXISTS idx_us_accidents_state ON us_accidents(state);
CREATE INDEX IF NOT EXISTS idx_us_accidents_start_time ON us_accidents(start_time);

COMMIT;
