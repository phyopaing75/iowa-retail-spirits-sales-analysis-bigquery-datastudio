-- =============================================================================
-- 07 · Q1 · Market share by store type and year (ALL stores)
-- -----------------------------------------------------------------------------
-- Hypothesis H1: Convenience stores gain share mainly by OPENING NEW STORES,
--                not through same-store growth.
-- Test         : compare this (all stores, incl. new and closed) with the
--                same-store growth in file 06.
--
-- Debugging note
--   v1 put EXTRACT(YEAR FROM f.date) directly inside PARTITION BY and failed:
--   "PARTITION BY expression references f.date which is neither grouped nor
--   aggregated". A window function that runs after GROUP BY can only use
--   grouped columns. Fix: aggregate first in a CTE, then apply the window.
--
-- Result (share of total sales %, active stores):
--   store_type   | 2023 | 2024 | 2025 | stores 2023 -> 2025
--   Grocery      | 42.9 | 42.1 | 41.7 |   491 ->   487
--   Liquor Store | 22.7 | 22.8 | 23.0 |   264 ->   295
--   Convenience  | 15.7 | 16.3 | 16.2 |   947 -> 1,032   (+85 stores)
--   Big Box      | 12.7 | 12.5 | 12.5 |    93 ->    94
--   Other        |  4.1 |  4.4 |  4.6 |   219 ->   247
--   Distributor  |  1.2 |  1.2 |  1.2 |     1 ->     1
--   Pharmacy     |  0.8 |  0.7 |  0.7 |    95 ->    87
--   Total market : ~$446M (2023) -> ~$425M (2025), -4.7%
--
-- Insight: convenience share rose 0.5 pts while same-store sales fell 4.7%
-- and sales per store fell ~10% (~$74K -> ~$67K). H1: CONFIRMED.
-- =============================================================================

CREATE OR REPLACE TABLE `iowa-retail-analysis.iowa_retail.q1_market_share` AS

-- 1. Aggregate: totals per year and store type
WITH totals AS (
  SELECT
    EXTRACT(YEAR FROM f.date)        AS year,
    st.store_type,
    COUNT(DISTINCT f.store_number)   AS active_stores,
    SUM(f.sale_dollars)              AS sales
  FROM `iowa-retail-analysis.iowa_retail.sales_raw` f
  JOIN `iowa-retail-analysis.iowa_retail.stores`    st USING (store_number)
  GROUP BY year, st.store_type
)

-- 2. Window: each store type's share of that year's total
SELECT
  year,
  store_type,
  active_stores,
  ROUND(sales)                                              AS sales,
  ROUND(100 * sales / SUM(sales) OVER (PARTITION BY year), 1) AS share_pct
FROM totals;
