-- =============================================================================
-- 01 · Check the date range and size of the source data
-- -----------------------------------------------------------------------------
-- Purpose : Before building anything, confirm how recent the public dataset is
--           and how many rows it holds. This decides which years to analyse.
-- Source  : bigquery-public-data.iowa_liquor_sales.sales
--           Iowa is an alcohol "control state": the state is the only spirits
--           wholesaler, so every licensed store's spirits purchase is recorded.
--
-- Result  : first_date = 2012-01-03 | last_date = 2026-04-30 | 34,016,839 rows
-- Decision: Use the three latest FULL calendar years, 2023-2025, so that
--           year-on-year comparisons are not distorted by a partial year.
-- =============================================================================

SELECT
  MIN(date) AS first_date,
  MAX(date) AS last_date,
  COUNT(*)  AS row_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
