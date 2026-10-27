-- =============================================================================
-- 02 · Create the FACT table: sales_raw
-- -----------------------------------------------------------------------------
-- Purpose : Copy only the rows (2023-2025) and columns the analysis needs into
--           my own project.
-- Why     : - The public table is ~34M rows; querying it repeatedly wastes the
--             free query quota (BigQuery bills by bytes scanned per column).
--           - Selecting 13 columns instead of SELECT * keeps every later query
--             small and fast.
-- Grain   : one row = one store's order of one product on one date.
--
-- Result  : 7,721,152 rows, 1.21 GB, stored in the US multi-region
--           (same location as the public dataset; BigQuery can't copy
--           data across locations).
-- =============================================================================

CREATE OR REPLACE TABLE `iowa-retail-analysis.iowa_retail.sales_raw` AS
SELECT
  date,
  store_number,
  store_name,
  city,
  county,
  category_name,        -- spirits category, e.g. "STRAIGHT BOURBON WHISKIES"
  vendor_name,
  item_description,
  bottle_volume_ml,     -- used later to split small / standard / large bottles
  state_bottle_retail,  -- price per bottle
  bottles_sold,
  sale_dollars,         -- main sales measure
  volume_sold_liters    -- used to separate VOLUME from PRICE effects
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE date BETWEEN '2023-01-01' AND '2025-12-31';
