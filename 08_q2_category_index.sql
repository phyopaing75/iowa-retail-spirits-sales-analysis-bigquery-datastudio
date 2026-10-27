-- =============================================================================
-- 08 · Q2 · Category index: convenience stores vs. total market (2025)
-- -----------------------------------------------------------------------------
-- Business question
--   Q2: Where are the assortment gaps?
-- Hypothesis H3: Convenience stores under-sell some of the categories that are
--                growing fastest in the overall market.
--
-- Method: category index (a standard category-management measure)
--   index = (category's share of CONVENIENCE sales)
--         / (category's share of TOTAL MARKET sales) x 100
--   > 100 : convenience stores over-sell the category (a strength)
--   < 100 : convenience stores under-sell it (a possible gap)
--   Combined with each category's market growth 2023 -> 2025, this shows
--   which gaps are worth closing (growing + under-indexed).
--
-- Key results (categories with >= 0.5% of the market):
--   category                      | index | market growth % | role
--   Whiskey Liqueur               |  269  |  +1.8  | strength, growing
--   American Schnapps             |  201  | +13.0  | strength, growing
--   Neutral Grain Spirits Flavored|  173  | -28.7  | over-sold, shrinking
--   American Vodkas               |  130  |  -3.6  | over-sold, shrinking
--   Canadian Whiskies             |  119  |  -9.1  | over-sold, shrinking
--   Straight Bourbon Whiskies     |   70  |  +3.4  | GAP, growing
--   100% Agave Tequila            |   77  |  +3.2  | GAP, growing
--   Cocktails/RTD                 |   37  | +16.2  | GAP, growing
--
-- Insight: convenience stores depend on value/flavored lines (vodka, whiskey
-- liqueur and Canadian whisky = ~50% of their spirits sales) and under-sell
-- premium categories (bourbon, 100% agave tequila, single malt 14, rye 29)
-- where the market is growing. H3: CONFIRMED.
-- =============================================================================

CREATE OR REPLACE TABLE `iowa-retail-analysis.iowa_retail.q2_category_index` AS

-- 1. Sales per category: convenience 2025, market 2025, market 2023
WITH cat AS (
  SELECT
    f.category_name,
    SUM(IF(EXTRACT(YEAR FROM f.date) = 2025 AND st.store_type = 'Convenience',
           f.sale_dollars, 0))                                    AS conv_sales_2025,
    SUM(IF(EXTRACT(YEAR FROM f.date) = 2025, f.sale_dollars, 0))  AS market_sales_2025,
    SUM(IF(EXTRACT(YEAR FROM f.date) = 2023, f.sale_dollars, 0))  AS market_sales_2023
  FROM `iowa-retail-analysis.iowa_retail.sales_raw` f
  JOIN `iowa-retail-analysis.iowa_retail.stores`    st USING (store_number)
  WHERE f.category_name IS NOT NULL
  GROUP BY f.category_name
),

-- 2. Each category's share of convenience sales and of market sales
--    (window over the aggregated CTE, the same two-stage pattern as file 07)
shares AS (
  SELECT
    *,
    conv_sales_2025   / SUM(conv_sales_2025)   OVER () AS conv_share,
    market_sales_2025 / SUM(market_sales_2025) OVER () AS market_share
  FROM cat
)

-- 3. Index and market growth
SELECT
  category_name,
  ROUND(conv_sales_2025)                                    AS conv_sales_2025,
  ROUND(market_sales_2025)                                  AS market_sales_2025,
  ROUND(100 * conv_share, 2)                                AS conv_share_pct,
  ROUND(100 * market_share, 2)                              AS market_share_pct,
  ROUND(100 * SAFE_DIVIDE(conv_share, market_share))        AS conv_index,
  -- SAFE_DIVIDE returns NULL instead of an error if a category had no 2023 sales
  ROUND(100 * (SAFE_DIVIDE(market_sales_2025, market_sales_2023) - 1), 1)
                                                            AS market_growth_pct
FROM shares;
