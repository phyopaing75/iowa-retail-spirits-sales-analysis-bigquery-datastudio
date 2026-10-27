-- =============================================================================
-- 03 · Create the DIMENSION table: stores (with a derived store_type)
-- -----------------------------------------------------------------------------
-- Problem : The source data has NO store-type column, but the whole analysis
--           compares convenience stores with grocery, liquor and big-box stores.
-- Solution: Classify each store from keywords in its name.
--
-- Design decisions
--   1. One row per store_number, using the store's MOST RECENT name.
--      Stores sometimes rename (e.g. Kum & Go -> Maverik). Using the latest
--      name guarantees each store gets exactly ONE type and is never counted
--      in two groups.
--   2. Rule order matters: the first matching rule wins.
--      - Big Box first, so "Walmart" isn't caught by the generic "mart" rule.
--      - Grocery matches "market" (not "mart") for independent grocers.
--      - Liquor Store comes BEFORE Convenience, so "X Liquor Mart" counts as a
--        liquor store.
--      - Distributor is its own type: wholesale licensees would distort
--        store-to-store comparisons.
--   3. Version 2 of the rules (this file) was refined after reviewing the 50
--      largest stores left as 'Other' in v1 (see 04_check_store_classification).
--
-- Result  : 'Other' fell from 16.5% of sales (v1) to 4.4% (v2).
-- Caveat  : Name-based classification is an assumption, documented in README.
-- =============================================================================

CREATE OR REPLACE TABLE `iowa-retail-analysis.iowa_retail.stores` AS

-- Step 1: keep each store's most recent name, city and county.
-- ARRAY_AGG(... ORDER BY date DESC LIMIT 1)[OFFSET(0)] is BigQuery's compact
-- "latest row per group" pattern (equivalent to ROW_NUMBER() ... WHERE rn = 1).
WITH latest AS (
  SELECT
    store_number,
    ARRAY_AGG(
      STRUCT(store_name, city, county)
      ORDER BY date DESC
      LIMIT 1
    )[OFFSET(0)] AS s
  FROM `iowa-retail-analysis.iowa_retail.sales_raw`
  GROUP BY store_number
)

-- Step 2: classify by keywords in the (lower-cased) store name.
-- r"..." is a regular expression: | means OR, ? makes a character optional,
-- \b...\b matches a whole word only.
SELECT
  store_number,
  s.store_name,
  s.city,
  s.county,
  CASE
    -- 1. Big box & warehouse clubs
    WHEN REGEXP_CONTAINS(LOWER(s.store_name),
         r"wal-?mart|sam's club|costco|target")
      THEN 'Big Box'

    -- 2. Grocery chains and independent grocers
    WHEN REGEXP_CONTAINS(LOWER(s.store_name),
         r"hy-?vee|fareway|aldi|price chopper|cash saver|super saver|grocery|supermarket|super market|food|market")
      THEN 'Grocery'

    -- 3. Pharmacies
    WHEN REGEXP_CONTAINS(LOWER(s.store_name),
         r"walgreens|cvs|osco|pharmacy|drug")
      THEN 'Pharmacy'

    -- 4. Wholesale licensees (kept separate)
    WHEN REGEXP_CONTAINS(LOWER(s.store_name),
         r"distributing|distributor")
      THEN 'Distributor'

    -- 5. Liquor & beverage stores, incl. large independents found in review
    WHEN REGEXP_CONTAINS(LOWER(s.store_name),
         r"liquor|wine|spirits|beverage|tobacco|smoke|bottle|beer|central city|another round|bootlegg|barzini")
      THEN 'Liquor Store'

    -- 6. Convenience: chains + common independent name patterns
    WHEN REGEXP_CONTAINS(LOWER(s.store_name),
         r"casey|kum & go|kwik|quik|quick|circle k|maverik|yesway|fas mart|git n go|fuel|gas|convenience|\bbp\b|stop|mart|xpress|express|pantry|jiffy|easygo|corner|mega saver")
      THEN 'Convenience'

    -- 7. Everything else (casinos, wineries, unclear independents)
    ELSE 'Other'
  END AS store_type
FROM latest;
