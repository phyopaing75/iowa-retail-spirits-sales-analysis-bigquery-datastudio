-- =============================================================================
-- 05 · Q1 · Same-store sales, volume and price by store type and year
-- -----------------------------------------------------------------------------
-- Business question
--   Q1: Is the convenience channel really growing?
--
-- Why "same-store"?
--   Total sales can rise simply because a chain OPENS more stores. Retailers
--   therefore report like-for-like ("same-store") sales: only stores that
--   traded in every period. Here: stores that bought spirits in ALL of
--   2023, 2024 and 2025.
--
-- Why liters and price per liter?
--   To split dollar growth into VOLUME (liters sold) and PRICE / MIX
--   ($ per liter). This tests H2: "dollar growth is partly price".
--
-- Output   : table q1_same_store (one row per year x store type)
-- Result (Convenience, same 877 stores):
--   year | sales   | liters | $ per liter
--   2023 | $66.2M  | 3.1M   | 21.6
--   2024 | $69.5M  | 3.1M   | 22.3     (+5.0% sales vs 2023)
--   2025 | $63.1M  | 2.8M   | 22.3     (-9.2% sales vs 2024, volume-driven)
-- Insight : the decline happened entirely in 2025, and it was volume, not price.
-- =============================================================================

CREATE OR REPLACE TABLE `iowa-retail-analysis.iowa_retail.q1_same_store` AS

-- 1. Yearly totals per store
WITH yearly AS (
  SELECT
    f.store_number,
    st.store_type,
    EXTRACT(YEAR FROM f.date)   AS year,
    SUM(f.sale_dollars)         AS sales,
    SUM(f.volume_sold_liters)   AS liters,
    SUM(f.bottles_sold)         AS bottles
  FROM `iowa-retail-analysis.iowa_retail.sales_raw` f
  JOIN `iowa-retail-analysis.iowa_retail.stores`    st USING (store_number)
  GROUP BY f.store_number, st.store_type, year
),

-- 2. The same-store group: stores active in all 3 years
same_stores AS (
  SELECT store_number
  FROM yearly
  GROUP BY store_number
  HAVING COUNT(DISTINCT year) = 3
)

-- 3. Same-store totals by store type and year
SELECT
  y.year,
  y.store_type,
  COUNT(DISTINCT y.store_number)          AS stores,
  ROUND(SUM(y.sales))                     AS sales,
  ROUND(SUM(y.liters))                    AS liters,
  SUM(y.bottles)                          AS bottles,
  ROUND(SUM(y.sales) / SUM(y.liters), 2)  AS price_per_liter   -- price + mix
FROM yearly y
JOIN same_stores USING (store_number)     -- keep same-store rows only
GROUP BY y.year, y.store_type;
