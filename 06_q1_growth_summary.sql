-- =============================================================================
-- 06 · Q1 · Same-store growth 2023 -> 2025, split into volume and price
-- -----------------------------------------------------------------------------
-- Hypothesis H2: Part of the dollar growth comes from higher price per liter,
--                not from selling more.
-- Reading it   : sales growth ≈ volume growth + price growth (approximately).
--
-- Technique    : conditional aggregation. IF(year = 2025, sales, 0) inside
--                SUM() picks one year's value, so 2023 and 2025 sit side by
--                side in one row without a self-join.
--
-- Result (same-store, 2023 -> 2025):
--   store_type   | sales % | volume % | price per liter %
--   Other        |  -0.2   |  -5.3    |  +5.4
--   Distributor  |  -0.8   |  +1.3    |  -2.1
--   Convenience  |  -4.7   |  -7.7    |  +3.3   <- highest price/mix gain
--   Liquor Store |  -5.9   |  -6.3    |  +0.5
--   Big Box      |  -6.0   |  -5.9    |  -0.1
--   Grocery      |  -6.4   |  -7.6    |  +1.3
--   Pharmacy     | -10.7   | -12.3    |  +1.8
--
-- Insight: same-store sales fell in EVERY format. Convenience fell least in
-- dollars only because price/mix (+3.3%) offset ~40% of its volume loss
-- (-7.7%). File 10 shows this is mostly a shift to small bottles (mix).
-- H2: CONFIRMED (mostly mix, not just higher prices).
-- =============================================================================

CREATE OR REPLACE TABLE `iowa-retail-analysis.iowa_retail.q1_growth_summary` AS
SELECT
  store_type,

  ROUND(100 * (SUM(IF(year = 2025, sales,  0))
             / SUM(IF(year = 2023, sales,  0)) - 1), 1)   AS sales_growth_pct,

  ROUND(100 * (SUM(IF(year = 2025, liters, 0))
             / SUM(IF(year = 2023, liters, 0)) - 1), 1)   AS volume_growth_pct,

  ROUND(100 * (MAX(IF(year = 2025, price_per_liter, NULL))
             / MAX(IF(year = 2023, price_per_liter, NULL)) - 1), 1)
                                                          AS price_growth_pct
FROM `iowa-retail-analysis.iowa_retail.q1_same_store`
GROUP BY store_type;
