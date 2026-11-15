-- Narrow time-series table: one row per measured value
CREATE TABLE measurement (
    ts         timestamptz      NOT NULL,
    line       text             NOT NULL,   -- e.g. 'finishing-1'
    device     text             NOT NULL,   -- e.g. 'robot-1', 'oven', 'conveyor-3'
    signal     text             NOT NULL,   -- e.g. 'base_g', 'hardener_g', 'temp_c', 'running'
    value      double precision NOT NULL,
    recipe     text,                        -- optional context
    order_no   text                         -- optional context
);

CREATE INDEX measurement_line_device_signal_ts
    ON measurement (line, device, signal, ts DESC);

-- Recipe targets for ratio monitoring
CREATE TABLE recipe_target (
    recipe        text PRIMARY KEY,
    target_ratio  double precision NOT NULL,   -- e.g. hardener / base = 0.10
    tolerance     double precision NOT NULL    -- e.g. 0.005 (absolute)
);

-- Read-only user for Grafana
CREATE ROLE grafana_ro LOGIN PASSWORD 'change-me';
GRANT USAGE ON SCHEMA public TO grafana_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO grafana_ro;
