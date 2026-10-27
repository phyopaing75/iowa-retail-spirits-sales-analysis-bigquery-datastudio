# Iowa Spirits: Convenience Store Category Review (BigQuery + Looker Studio)

> **Convenience stores' spirits sales fell 4.7% like-for-like (2023–2025); their apparent market-share gain came only from a net 85 more stores. Reallocating shelf space to small-format bourbon, 100% agave tequila and RTD cocktails is worth up to ≈ $4,000 per store per year, enough to offset the decline.**

**[View the interactive dashboard →](https://datastudio.google.com/reporting/a1bce2d1-7fcb-4bfb-b94c-0754ac625020)**

---

## Business problem

A convenience-store chain must decide whether to **expand spirits shelf space** next year, and **which categories and bottle sizes** should get it. Spirits are a high-margin category, but space is limited and every new line replaces an existing one.

**Decision owner:** Head of Category Management
**My role:** data analyst supporting the category team, using Iowa's statewide spirits purchase data as a market benchmark.

## Data

| | |
|---|---|
| **Source** | BigQuery public dataset `bigquery-public-data.iowa_liquor_sales.sales` |
| **What it records** | Iowa is an alcohol *control state*: the state is the only spirits wholesaler, so every licensed store's spirits purchase is recorded (store, product, category, bottle size, bottles, dollars, liters) |
| **Full dataset** | 34.0M rows, Jan 2012 – Apr 2026 |
| **Analysis window** | 3 full years, 2023–2025: **7.7M rows**, thousands of stores |

## Hypotheses

| | Hypothesis | Result |
|---|---|---|
| **H1** | Convenience stores gain share mainly by opening new stores, not through same-store growth | ✅ Confirmed |
| **H2** | Part of the dollar growth comes from higher price per liter, not more volume | ✅ Confirmed, mostly a **mix shift** to small bottles |
| **H3** | Convenience stores under-sell some of the fastest-growing categories | ✅ Confirmed |

## Findings

### Q1 · Is the convenience channel really growing? **No.**

| Store type | Same-store sales 2023→25 | Volume | Price per liter |
|---|---|---|---|
| **Convenience** | **−4.7%** | **−7.7%** | **+3.3%** |
| Liquor Store | −5.9% | −6.3% | +0.5% |
| Big Box | −6.0% | −5.9% | −0.1% |
| Grocery | −6.4% | −7.6% | +1.3% |

- **The whole spirits market shrank** from about $446M to $425M (−4.7%). Same-store sales fell in every store format.
- **Convenience share rose from 15.7% to 16.2%, but only because the store count grew by a net 85** (947 → 1,032 active stores). Like-for-like sales fell 4.7%, and sales per store fell about 10%.
- **The decline is a 2025 event.** Same-store convenience sales grew 5.0% in 2024, then fell 9.2% in 2025, driven by volume, not price.
- **Convenience stores sell about 5× less spirits per store** than grocery or liquor stores (≈ $67K vs. ≈ $330–365K a year).

### Q2 · Where are the assortment gaps?

**Convenience index** = category's share of convenience sales ÷ its share of total market sales × 100. 100 means convenience stores sell the category at the same rate as the market; 130 means 30% above, 70 means 30% below.

| Category | C-store index | Market growth 2023→25 | Role |
|---|---|---|---|
| Whiskey Liqueur | 269 | +1.8% | Strength (protect) |
| American Schnapps | 201 | +13.0% | Strength (protect) |
| Canadian Whiskies | 119 | −9.1% | Over-sold & shrinking (trim) |
| Neutral Grain Spirits Flavored | 173 | −28.7% | Over-sold & shrinking (trim) |
| **Straight Bourbon Whiskies** | **70** | **+3.4%** | **Gap (add)** |
| **100% Agave Tequila** | **77** | **+3.2%** | **Gap (add)** |
| **Cocktails/RTD** | **37** | **+16.2%** | **Gap (add)** |

- **Convenience stores rely on value and flavored lines.** American vodka, whiskey liqueur and Canadian whisky make up about 50% of their spirits sales, and two of the three are shrinking.
- **They under-sell premium categories,** where the market is growing: bourbon, 100% agave tequila, single malt (index 14) and rye (29).
- **Convenience is a small-bottle business.** Bottles of 200 ml or less are **31.2%** of convenience sales against **10.4%** for the market (index **300**).
- **The shift to small bottles is accelerating:** 26.6% → 27.6% → 31.2% of convenience sales (2023 → 2025). In 2025, small bottles brought in 31% of the dollars from only 12% of the liquid, which explains most of the +3.3% price-per-liter rise.

### Q3 · How big is the opportunity? **≈ $4,028 per store per year**

| Category | Opportunity, all c-stores | Per store per year |
|---|---|---|
| Straight Bourbon Whiskies | $1.97M | $1,911 |
| 100% Agave Tequila | $1.24M | $1,205 |
| Cocktails/RTD | $0.94M | $912 |
| **Top 3 total** | **≈ $4.2M** | **≈ $4,028** |

That's about **6%** of an average convenience store's ≈ $66.6K spirits sales, more than the 4.7% same-store decline. It's an **upper bound**: it assumes convenience shoppers would buy these categories at the market-average rate.

Categories I left out on purpose: imported vodkas (market flat, +0.5%), gift/specialty packages (+47.6% likely reflects seasonal packaging or coding, not demand), and two small niches with a poor convenience fit.

## Recommendation

**Don't expand total spirits space; reallocate it.**

1. **Add small-format (≤200 ml) straight bourbon, 100% agave tequila and RTD cocktails.** These are the categories growing in a shrinking market, in the bottle size convenience shoppers increasingly buy. Worth up to ≈ $4,000 per store per year.
2. **Fund the space by trimming declining value lines** where convenience stores over-index: Canadian whisky (index 119, −9.1%) and flavored grain spirits (173, −28.7%).
3. **Protect growing strengths:** whiskey liqueur (269, +1.8%) and American schnapps (201, +13.0%).

## Method

**Data model.** A small star schema in BigQuery:

| Table | Type | Description |
|---|---|---|
| `sales_raw` | Fact | 2023–2025 purchases, 13 columns, 7.7M rows |
| `stores` | Dimension | One row per store, with a derived `store_type` |
| `q1_*`, `q2_*`, `q3_*` | Summary | Small result tables that feed the dashboard |

**Key analytical choices**

- **Store classification.** The data has no store-type column, so I classified stores from keywords in their names. Each store uses its *most recent* name, so renamed stores aren't counted twice. I refined the rules by reviewing the 50 largest unmatched stores, which cut unclassified sales from **16.5% to 4.4%**.
- **Same-store sales.** Only stores active in all three years (877 convenience stores), so new openings can't inflate growth.
- **Volume vs. price.** Dollar growth is split into liters sold and price per liter, which reflects both price and product mix.
- **Category index.** The standard category-management comparison of a channel's mix against the total market. Multiplying by 100 puts the market average at 100, so the index reads as "% above or below average". The same index is applied to bottle sizes; because shares add up to 100%, an over-index in one size is always balanced by an under-index in another.
- **Index + growth together.** Neither measure is enough alone: growth shows where demand is going, the index shows whether convenience stores already capture it. Only categories that are growing *and* under-indexed *and* large enough were recommended.
- **Opportunity sizing.** The gap between market share and convenience share in each under-indexed, growing category, converted into dollars per store.

**SQL techniques used:** CTEs, window functions over aggregates (`SUM(SUM(x)) OVER ()`, `PARTITION BY`), conditional aggregation (`SUM(IF(...))`), `ARRAY_AGG ... ORDER BY ... LIMIT 1` for the latest row per group, regex classification (`REGEXP_CONTAINS`), `SAFE_DIVIDE` and `CROSS JOIN`.

## Limitations

- **Store purchases, not shopper sales.** They track sales over months, but not day by day.
- **Store types are classified from names;** 4.4% of sales remain unclassified.
- **One US state, spirits only.** Many malt-based RTD cocktails aren't in this data, so the RTD opportunity may be understated.
- **The opportunity is an upper bound, not a forecast.**
- **The data shows *when* the 2025 decline happened, not *why*.**

## Repository structure

```
├── README.md
├── images/
│   └── dashboard.png
└── sql/
    ├── 01_check_date_range.sql            # source size & date range
    ├── 02_create_sales_raw.sql            # fact table (2023–2025)
    ├── 03_create_stores_dimension.sql     # store dimension + store_type
    ├── 04_check_store_classification.sql  # validation & refinement
    ├── 05_q1_same_store.sql               # Q1: same-store totals by year
    ├── 06_q1_growth_summary.sql           # Q1: growth = volume + price
    ├── 07_q1_market_share.sql             # Q1: market share, all stores
    ├── 08_q2_category_index.sql           # Q2: category index vs. growth
    ├── 09_q2_bottle_size_index.sql        # Q2: bottle-size index
    ├── 10_q2_small_bottle_trend.sql       # Q2: small-bottle mix trend
    └── 11_q3_opportunity.sql              # Q3: opportunity sizing
```

Each SQL file opens with a comment block covering the business question, the method, the actual result and the insight.

## How to reproduce

1. Open the [BigQuery sandbox](https://console.cloud.google.com/bigquery) (free, no credit card) and create a project.
2. Create a dataset in the **US** multi-region (the public data is stored in the US).
3. Replace `iowa-retail-analysis` with your project ID and run the SQL files in order, 01 → 11.
4. Connect Looker Studio to the `q1_*`, `q2_*` and `q3_*` tables.

## Tools

**Google BigQuery** (SQL) · **Looker Studio** (dashboard)

---

*Phyo Paing · [Portfolio](https://phyopaing75.github.io/phyopaing-portfolio) · [LinkedIn](https://www.linkedin.com/in/phyo-paing-4b0477189/) · [GitHub](https://github.com/phyopaing75)*
