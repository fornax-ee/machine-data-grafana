-- Grafana (PostgreSQL data source) queries.
-- $__timeFilter(), $__interval and $__timeGroupAlias() are Grafana macros.

-- 1) Raw signal over time
SELECT $__timeGroupAlias(ts, $__interval), avg(value) AS temp_c
FROM measurement
WHERE $__timeFilter(ts) AND line = 'finishing-1' AND device = 'oven' AND signal = 'temp_c'
GROUP BY 1 ORDER BY 1;

-- 2) Mixing ratio per robot vs. recipe target with tolerance band
WITH dosed AS (
    SELECT date_trunc('minute', ts) AS t, device, recipe,
           sum(value) FILTER (WHERE signal = 'base_g')     AS base_g,
           sum(value) FILTER (WHERE signal = 'hardener_g') AS hardener_g
    FROM measurement
    WHERE $__timeFilter(ts) AND line = 'finishing-1' AND signal IN ('base_g', 'hardener_g')
    GROUP BY 1, 2, 3
)
SELECT d.t AS time,
       d.device,
       d.hardener_g / NULLIF(d.base_g, 0)  AS ratio,
       r.target_ratio,
       r.target_ratio - r.tolerance        AS lower_limit,
       r.target_ratio + r.tolerance        AS upper_limit
FROM dosed d
JOIN recipe_target r USING (recipe)
WHERE d.base_g > 0
ORDER BY 1;

-- 3) Share of time out of tolerance per recipe (table panel)
WITH dosed AS (
    SELECT date_trunc('minute', ts) AS t, recipe,
           sum(value) FILTER (WHERE signal = 'base_g')     AS base_g,
           sum(value) FILTER (WHERE signal = 'hardener_g') AS hardener_g
    FROM measurement
    WHERE $__timeFilter(ts) AND line = 'finishing-1'
    GROUP BY 1, 2
)
SELECT d.recipe,
       count(*) AS minutes,
       round(100.0 * avg((abs(d.hardener_g / d.base_g - r.target_ratio) > r.tolerance)::int), 1) AS pct_out_of_tolerance
FROM dosed d JOIN recipe_target r USING (recipe)
WHERE d.base_g > 0
GROUP BY d.recipe ORDER BY pct_out_of_tolerance DESC;

-- 4) Availability: share of time a device reported running = 1
SELECT $__timeGroupAlias(ts, '1h'),
       100 * avg(value) AS availability_pct
FROM measurement
WHERE $__timeFilter(ts) AND line = 'finishing-1' AND device = 'conveyor-3' AND signal = 'running'
GROUP BY 1 ORDER BY 1;
