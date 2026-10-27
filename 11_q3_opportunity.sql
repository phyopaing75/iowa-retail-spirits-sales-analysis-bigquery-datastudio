-- =============================================================================
-- 11 · Q3 · Size the opportunity in the gap categories
-- -----------------------------------------------------------------------------
-- Business question
--   Q3: How big is the opportunity, in dollars per store?
--
-- Selection: categories that are
--   - under-indexed in convenience stores    (conv_index < 100)
--   - growing in the overall market           (market_growth_pct > 0)
--   - large enough to matter                  (>= 0.5% of market sales)
--
-- Opportunity = extra sales if convenience stores' share of each category
--   matched the market's share:
--   (market share % - c-store share %) x total 2025 c-store sales
--   ... then divided by the number of active convenience stores.
--
-- IMPORTANT: this is an UPPER BOUND, not a forecast. It assumes convenience
-- shoppers would buy these categories at the market-average rate.
--
-- Result:
--   category                             | index | growth % | total $    | $/store
--   Straight Bourbon Whiskies            |  70   |  +3.4    | 1,971,883  | 1,911
--   100% Agave Tequila                   |  77   |  +3.2    | 1,243,592  | 1,205
--   Cocktails/RTD                        |  37   | +16.2    |   941,282  |   912
--   Imported Vodkas                      |  55   |  +0.5    |   879,446  |   852
--   Temporary & Specialty Packages       |  70   | +47.6    |   673,326  |   652
--   Imported Distilled Spirits Specialty |   5   |  +9.2    |   432,852  |   419
--   Coffee Liqueurs                      |  11   |  +3.2    |   322,922  |   313
--
-- Analyst judgement: the recommendation uses only the TOP 3.
--   - Imported vodkas: market is flat (+0.5%), not really growing.
--   - Temporary & specialty packages: gift sets; +47.6% is likely seasonal
--     packaging or a coding change, not lasting demand.
--   - Imported specialty, coffee liqueurs: small niches, poor convenience fit.
--
-- Top 3 total: ~$4.2M across convenience stores = ~$4,028 per store per year,
-- ~6% of an average store's ~$66.6K spirits sales (2025), more than the
-- 4.7% same-store decline found in Q1.
-- =============================================================================

CREATE OR REPLACE TABLE `iowa-retail-analysis.iowa_retail.q3_opportunity` AS

-- 2025 convenience totals: total sales and number of active stores
WITH conv AS (
  SELECT
    COUNT(DISTINCT f.store_number)  AS n_stores,
    SUM(f.sale_dollars)             AS conv_total
  FROM `iowa-retail-analysis.iowa_retail.sales_raw` f
  JOIN `iowa-retail-analysis.iowa_retail.stores`    st USING (store_number)
  WHERE st.store_type = 'Convenience'
    AND EXTRACT(YEAR FROM f.date) = 2025
)

SELECT
  q.category_name,
  q.conv_index,
  q.market_growth_pct,
  -- share gap (percentage points) x total convenience sales
  ROUND((q.market_share_pct - q.conv_share_pct) / 100 * c.conv_total)
                                                    AS gap_sales_total,
  -- the same gap, per convenience store
  ROUND((q.market_share_pct - q.conv_share_pct) / 100 * c.conv_total / c.n_stores)
                                                    AS gap_sales_per_store
FROM `iowa-retail-analysis.iowa_retail.q2_category_index` q
CROSS JOIN conv c          -- attaches the single row of totals to every category
WHERE q.conv_index < 100
  AND q.market_growth_pct > 0
  AND q.market_share_pct >= 0.5
ORDER BY gap_sales_total DESC;
