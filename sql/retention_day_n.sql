/*
 * Day-N Retention Analysis (D1, D7, D30)
 * 
 * Purpose: Calculate standard Day-1, Day-7, and Day-30 retention metrics
 * 
 * Cohort Definition: Date of first view_item event
 * Activity Definition: ≥1 commerce event on exact day offset
 * Retention Metric: % of cohort active on day N
 * 
 * Output: D1, D7, D30 retention rates by cohort and device category
 */

WITH base_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    COALESCE(device.category, 'unknown') AS device_category
  FROM 
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
    AND user_pseudo_id IS NOT NULL
),

-- Define user cohorts based on first view_item event
user_cohorts AS (
  SELECT
    user_pseudo_id,
    MIN(event_date) AS cohort_date,
    MIN(device_category) AS device_category,
    -- Group by month for aggregation
    DATE_TRUNC(MIN(event_date), MONTH) AS cohort_month
  FROM base_events
  WHERE event_name = 'view_item'
  GROUP BY user_pseudo_id
),

-- Calculate day offset for each activity event
user_activity_with_offset AS (
  SELECT
    e.user_pseudo_id,
    c.cohort_date,
    c.cohort_month,
    c.device_category,
    e.event_date,
    DATE_DIFF(e.event_date, c.cohort_date, DAY) AS day_offset
  FROM base_events e
  INNER JOIN user_cohorts c
    ON e.user_pseudo_id = c.user_pseudo_id
),

-- Count active users at specific day offsets (D1, D7, D30)
day_n_activity AS (
  SELECT
    cohort_month,
    device_category,
    day_offset,
    COUNT(DISTINCT user_pseudo_id) AS active_users
  FROM user_activity_with_offset
  WHERE day_offset IN (0, 1, 7, 30)  -- D0 (cohort day), D1, D7, D30
  GROUP BY cohort_month, device_category, day_offset
),

-- Get cohort sizes
cohort_sizes AS (
  SELECT
    cohort_month,
    device_category,
    COUNT(DISTINCT user_pseudo_id) AS cohort_size
  FROM user_cohorts
  GROUP BY cohort_month, device_category
)

-- Calculate retention rates for each day offset
SELECT
  s.cohort_month,
  s.device_category,
  a.day_offset,
  s.cohort_size,
  COALESCE(a.active_users, 0) AS active_users,
  ROUND(SAFE_DIVIDE(COALESCE(a.active_users, 0), s.cohort_size) * 100, 2) AS retention_rate
FROM cohort_sizes s
LEFT JOIN day_n_activity a
  ON s.cohort_month = a.cohort_month
  AND s.device_category = a.device_category
WHERE s.cohort_size >= 100  -- Filter small cohorts
ORDER BY 
  s.cohort_month,
  a.day_offset,
  s.device_category;

/*
 * Alternative: Pivoted View for Easier Analysis
 * 
 * SELECT
 *   cohort_month,
 *   device_category,
 *   cohort_size,
 *   MAX(CASE WHEN day_offset = 0 THEN retention_rate END) AS d0_retention,
 *   MAX(CASE WHEN day_offset = 1 THEN retention_rate END) AS d1_retention,
 *   MAX(CASE WHEN day_offset = 7 THEN retention_rate END) AS d7_retention,
 *   MAX(CASE WHEN day_offset = 30 THEN retention_rate END) AS d30_retention
 * FROM (SELECT * FROM above query)
 * GROUP BY cohort_month, device_category, cohort_size
 * ORDER BY cohort_month, device_category;
 */
