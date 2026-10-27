-- =============================================================================
-- 04 · Validate the store classification
-- -----------------------------------------------------------------------------
-- Purpose : A derived column is only useful if it's accurate. These two checks
--           measure how much of the market is left unclassified and show
--           which stores to fix.
-- Target  : 'Other' below ~10% of total sales.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 4a · Share of sales by store type
-- -----------------------------------------------------------------------------
-- SUM(SUM(x)) OVER () = a window function over the GROUPED totals, giving the
-- grand total on every row so each group can be divided by it in one query.
--
-- Result (v1 rules): Other = 16.5% of sales  -> too high, review in 4b
-- Result (v2 rules, final):
--   store_type    | stores | sales_share_pct
--   Grocery       |    532 | 42.2
--   Liquor Store  |    340 | 22.8
--   Convenience   |  1,104 | 16.1
--   Big Box       |     94 | 12.6
--   Other         |    295 |  4.4
--   Distributor   |      1 |  1.2
--   Pharmacy      |     96 |  0.8
-- Insight: convenience is the most numerous format but holds only 16% of sales.
-- -----------------------------------------------------------------------------

SELECT
  st.store_type,
  COUNT(DISTINCT f.store_number)                             AS stores,
  ROUND(100 * SUM(f.sale_dollars)
            / SUM(SUM(f.sale_dollars)) OVER (), 1)           AS sales_share_pct
FROM `iowa-retail-analysis.iowa_retail.sales_raw` f     -- fact
JOIN `iowa-retail-analysis.iowa_retail.stores`    st    -- dimension
  USING (store_number)
GROUP BY st.store_type
ORDER BY sales_share_pct DESC;


-- -----------------------------------------------------------------------------
-- 4b · The biggest stores still classified as 'Other'
-- -----------------------------------------------------------------------------
-- Fixing the largest unmatched stores moves the most sales, so review them
-- in order of size.
--
-- What the v1 review found (and how v2 rules in 03 fixed it):
--   - Large independent liquor stores without "liquor" in the name
--     (Central City 2 ~$40.6M, Another Round, Bootlegging Barzinis,
--      Beer Thirty stores)                               -> Liquor Store
--   - A wholesaler (Benz Distributing ~$15.6M)            -> Distributor
--   - Independent convenience stores (…Mart, Quick Stop, Xpress, Pantry,
--     Jiffy, EasyGo)                                      -> Convenience
--   - Independent grocers (…Super Market, Neighborhood Market) -> Grocery
--   - Osco (Osco Drug)                                    -> Pharmacy
--   - Casinos and a winery                                -> left as Other
-- -----------------------------------------------------------------------------

SELECT
  st.store_name,
  ROUND(SUM(f.sale_dollars)) AS sales      -- total 2023-2025 sales
FROM `iowa-retail-analysis.iowa_retail.sales_raw` f
JOIN `iowa-retail-analysis.iowa_retail.stores`    st USING (store_number)
WHERE st.store_type = 'Other'
GROUP BY st.store_name
ORDER BY sales DESC
LIMIT 50;
