-- =============================================================================
-- 10 · Q2 · Small-bottle share of convenience sales, by year
-- -----------------------------------------------------------------------------
-- Purpose : Test whether convenience stores' +3.3% price-per-liter growth
--           (file 06) comes from higher prices or from a MIX SHIFT toward
--           small bottles, which cost more per liter.
-- Logic   : if small bottles' share of convenience sales ROSE over time,
--           part of the price-per-liter increase is mix, not price.
--
-- Result:
--   year | small share of sales % | small share of liters %
--   2023 |         26.6           |          9.7
--   2024 |         27.6           |         10.8
--   2025 |         31.2           |         12.2
--
-- Insight: small bottles' share rose 4.6 pts in two years (3.6 of them in
-- 2025). In 2025 they brought in 31% of convenience dollars from only 12% of
-- the liquid. The price-per-liter rise is largely MIX, and the shift to
-- small formats is accelerating -> supports adding premium SMALL formats.
-- =============================================================================

CREATE OR REPLACE TABLE `iowa-retail-analysis.iowa_retail.q2_small_bottle_trend` AS
SELECT
  EXTRACT(YEAR FROM f.date) AS year,
  ROUND(100 * SUM(IF(f.bottle_volume_ml <= 200, f.sale_dollars, 0))
            / SUM(f.sale_dollars), 1)            AS small_share_of_sales_pct,
  ROUND(100 * SUM(IF(f.bottle_volume_ml <= 200, f.volume_sold_liters, 0))
            / SUM(f.volume_sold_liters), 1)      AS small_share_of_liters_pct
FROM `iowa-retail-analysis.iowa_retail.sales_raw` f
JOIN `iowa-retail-analysis.iowa_retail.stores`    st USING (store_number)
WHERE st.store_type = 'Convenience'
GROUP BY year;
