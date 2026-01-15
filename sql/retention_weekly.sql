/*
 * Weekly Cohort Retention Analysis
 * 
 * Purpose: Measure weekly cohort retention using behavioral activity definition
 * 
 * Cohort Definition: Week of first view_item event
 * Activity Definition: ≥1 commerce event in a given week
 * Retention Metric: % of cohort active in week N
 * 
 * Output: Retention rates by cohort week and week number
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
    -- Cohort week is the Monday of the week containing first view
    DATE_TRUNC(MIN(event_date), WEEK(MONDAY)) AS cohort_week
  FROM base_events
  WHERE event_name = 'view_item'
  GROUP BY user_pseudo_id
),

-- All user activity events with cohort information
user_activity AS (
  SELECT
    e.user_pseudo_id,
    e.event_date,
    c.cohort_week,
    c.device_category,
    -- Calculate which week number this activity falls into
    DATE_DIFF(DATE_TRUNC(e.event_date, WEEK(MONDAY)), c.cohort_week, WEEK) AS week_number
  FROM base_events e
  INNER JOIN user_cohorts c
    ON e.user_pseudo_id = c.user_pseudo_id
),

-- Count active users per cohort per week
cohort_activity AS (
  SELECT
    cohort_week,
    week_number,
    device_category,
    COUNT(DISTINCT user_pseudo_id) AS active_users
  FROM user_activity
  GROUP BY cohort_week, week_number, device_category
),

-- Get cohort sizes
cohort_sizes AS (
  SELECT
    cohort_week,
    device_category,
    COUNT(DISTINCT user_pseudo_id) AS cohort_size
  FROM user_cohorts
  GROUP BY cohort_week, device_category
)

-- Calculate retention rates
SELECT
  a.cohort_week,
  a.week_number,
  a.device_category,
  s.cohort_size,
  a.active_users,
  ROUND(SAFE_DIVIDE(a.active_users, s.cohort_size) * 100, 2) AS retention_rate
FROM cohort_activity a
INNER JOIN cohort_sizes s
  ON a.cohort_week = s.cohort_week
  AND a.device_category = s.device_category
WHERE 
  a.week_number BETWEEN 0 AND 8  -- Focus on first 8 weeks
  AND s.cohort_size >= 100  -- Filter small cohorts for statistical reliability
ORDER BY 
  a.cohort_week,
  a.week_number,
  a.device_category;

/*
 * Validation Query: Week 0 should always be 100% retention
 * 
 * SELECT cohort_week, device_category, retention_rate
 * FROM (SELECT * FROM above query)
 * WHERE week_number = 0 AND retention_rate < 99
 */
