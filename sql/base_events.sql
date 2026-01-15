/*
 * Base Event Extraction
 * 
 * Purpose: Extract and clean GA4 event data for funnel and retention analysis
 * 
 * Output: User-level events with timestamps, event types, and device category
 * 
 * Data Quality Notes:
 * - Filters to commerce-relevant events only
 * - Handles null device categories explicitly
 * - Deduplicates by (user, event, timestamp)
 */

WITH base_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    device.category AS device_category,
    -- Extract event value for potential future analysis
    CAST(ecommerce.purchase_revenue AS FLOAT64) AS purchase_revenue
  FROM 
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    -- Filter to 2021 data for faster processing (can expand if needed)
    _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
    -- Only commerce funnel events
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
    -- Remove null users
    AND user_pseudo_id IS NOT NULL
)

SELECT
  user_pseudo_id,
  event_name,
  event_timestamp,
  event_date,
  -- Handle null device categories
  COALESCE(device_category, 'unknown') AS device_category,
  purchase_revenue
FROM base_events
-- Deduplicate any exact duplicates
GROUP BY 
  user_pseudo_id,
  event_name,
  event_timestamp,
  event_date,
  device_category,
  purchase_revenue
ORDER BY 
  user_pseudo_id,
  event_timestamp;
