/*
 * User-Level Ordered Funnel Analysis
 * 
 * Purpose: Build user-level funnel with strict event ordering and 30-day window
 * 
 * Funnel Stages:
 * 1. Product View (view_item)
 * 2. Add to Cart (add_to_cart)
 * 3. Begin Checkout (begin_checkout)
 * 4. Purchase (purchase)
 * 
 * Business Rules:
 * - User-level grain (first occurrence of each event)
 * - Strict temporal ordering enforced
 * - 30-day window from first product view
 * - Segmented by device category
 * 
 * Validation: User counts must decrease monotonically across stages
 */

WITH base_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    COALESCE(device.category, 'unknown') AS device_category
  FROM 
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
    AND user_pseudo_id IS NOT NULL
),

-- Get first occurrence of each funnel stage per user
user_funnel_events AS (
  SELECT
    user_pseudo_id,
    device_category,
    MIN(CASE WHEN event_name = 'view_item' THEN event_timestamp END) AS view_timestamp,
    MIN(CASE WHEN event_name = 'add_to_cart' THEN event_timestamp END) AS add_timestamp,
    MIN(CASE WHEN event_name = 'begin_checkout' THEN event_timestamp END) AS checkout_timestamp,
    MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp END) AS purchase_timestamp
  FROM base_events
  GROUP BY user_pseudo_id, device_category
),

-- Apply funnel ordering and 30-day window constraints
ordered_funnel AS (
  SELECT
    user_pseudo_id,
    device_category,
    view_timestamp,
    -- Add to cart must happen AFTER view
    CASE 
      WHEN add_timestamp > view_timestamp 
        AND add_timestamp <= view_timestamp + (30 * 24 * 60 * 60 * 1000000) -- 30 days in microseconds
      THEN add_timestamp 
    END AS add_timestamp,
    -- Checkout must happen AFTER add to cart
    CASE 
      WHEN checkout_timestamp > add_timestamp
        AND checkout_timestamp <= view_timestamp + (30 * 24 * 60 * 60 * 1000000)
      THEN checkout_timestamp 
    END AS checkout_timestamp,
    -- Purchase must happen AFTER checkout
    CASE 
      WHEN purchase_timestamp > checkout_timestamp
        AND purchase_timestamp <= view_timestamp + (30 * 24 * 60 * 60 * 1000000)
      THEN purchase_timestamp 
    END AS purchase_timestamp
  FROM user_funnel_events
  WHERE view_timestamp IS NOT NULL
)

-- Final funnel with conversion flags
SELECT
  user_pseudo_id,
  device_category,
  view_timestamp,
  add_timestamp,
  checkout_timestamp,
  purchase_timestamp,
  -- Conversion flags for easier aggregation
  TRUE AS reached_view,
  CASE WHEN add_timestamp IS NOT NULL THEN TRUE ELSE FALSE END AS reached_add,
  CASE WHEN checkout_timestamp IS NOT NULL THEN TRUE ELSE FALSE END AS reached_checkout,
  CASE WHEN purchase_timestamp IS NOT NULL THEN TRUE ELSE FALSE END AS reached_purchase
FROM ordered_funnel
ORDER BY user_pseudo_id;

/*
 * Aggregation Query for Conversion Rates (run separately or in notebook)
 * 
 * SELECT
 *   device_category,
 *   COUNT(DISTINCT user_pseudo_id) AS total_users,
 *   SUM(CASE WHEN reached_view THEN 1 ELSE 0 END) AS view_users,
 *   SUM(CASE WHEN reached_add THEN 1 ELSE 0 END) AS add_users,
 *   SUM(CASE WHEN reached_checkout THEN 1 ELSE 0 END) AS checkout_users,
 *   SUM(CASE WHEN reached_purchase THEN 1 ELSE 0 END) AS purchase_users,
 *   SAFE_DIVIDE(SUM(CASE WHEN reached_add THEN 1 ELSE 0 END), 
 *                SUM(CASE WHEN reached_view THEN 1 ELSE 0 END)) AS view_to_add_rate,
 *   SAFE_DIVIDE(SUM(CASE WHEN reached_checkout THEN 1 ELSE 0 END), 
 *                SUM(CASE WHEN reached_add THEN 1 ELSE 0 END)) AS add_to_checkout_rate,
 *   SAFE_DIVIDE(SUM(CASE WHEN reached_purchase THEN 1 ELSE 0 END), 
 *                SUM(CASE WHEN reached_checkout THEN 1 ELSE 0 END)) AS checkout_to_purchase_rate,
 *   SAFE_DIVIDE(SUM(CASE WHEN reached_purchase THEN 1 ELSE 0 END), 
 *                SUM(CASE WHEN reached_view THEN 1 ELSE 0 END)) AS overall_conversion_rate
 * FROM (SELECT * FROM ordered_funnel)
 * GROUP BY device_category
 * ORDER BY total_users DESC;
 */
