-- =============================================================================
-- 09 · Q2 · Bottle-size index: convenience stores vs. total market (2025)
-- -----------------------------------------------------------------------------
-- Purpose : Check HOW convenience shoppers buy. Small bottles cost more per
--           liter, so a high small-bottle index would also help explain why
--           convenience stores' price per liter rose fastest (file 06).
-- Index   : same definition as file 08, applied to bottle-size groups.
--
-- Result:
--   bottle_size            | c-store share % | market share % | index
--   Small (≤200 ml)        |      31.2       |      10.4      |  300
--   Standard (201–750 ml)  |      54.6       |      50.2      |  109
--   Large (>750 ml)        |      14.3       |      39.4      |   36
--
-- Insight: convenience is a small-bottle, "buy for now" business: small bottles
-- make up 3x the share of sales they do in the market.
-- =============================================================================

CREATE OR REPLACE TABLE `iowa-retail-analysis.iowa_retail.q2_bottle_size_index` AS

-- 1. Group 2025 sales into three bottle-size bands
WITH sized AS (
  SELECT
    CASE
      WHEN f.bottle_volume_ml <= 200 THEN 'Small (≤200 ml)'
      WHEN f.bottle_volume_ml <= 750 THEN 'Standard (201–750 ml)'
      ELSE 'Large (>750 ml)'
    END                                                         AS bottle_size,
    SUM(IF(st.store_type = 'Convenience', f.sale_dollars, 0))   AS conv_sales,
    SUM(f.sale_dollars)                                         AS market_sales
  FROM `iowa-retail-analysis.iowa_retail.sales_raw` f
  JOIN `iowa-retail-analysis.iowa_retail.stores`    st USING (store_number)
  WHERE EXTRACT(YEAR FROM f.date) = 2025
  GROUP BY bottle_size
),

-- 2. Shares within convenience and within the market
shares AS (
  SELECT
    bottle_size,
    conv_sales   / SUM(conv_sales)   OVER () AS conv_share,
    market_sales / SUM(market_sales) OVER () AS market_share
  FROM sized
)

-- 3. Index
SELECT
  bottle_size,
  ROUND(100 * conv_share, 1)                          AS conv_share_pct,
  ROUND(100 * market_share, 1)                        AS market_share_pct,
  ROUND(100 * SAFE_DIVIDE(conv_share, market_share))  AS conv_index
FROM shares;
