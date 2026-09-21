# U.S. Used-Car Market Analysis

A Spring 2021 snapshot of the Craigslist used-vehicle market — 251,092 deduplicated listings analyzed across Excel, Power BI, Tableau, and SQL.

**Tools used:** Excel · Power BI · Tableau · SQL (MySQL)

## Overview

This project analyzes 251,092 deduplicated used-vehicle listings scraped from Craigslist between April 4 and May 5, 2021 — a narrow window that happens to fall near the peak of the pandemic-era used-car price spike. The analysis explores how price relates to vehicle age, mileage, body type, fuel type, title status, brand, and geography, and specifically examines whether the dataset carries a detectable "fingerprint" of COVID-19's disruption to the used-car market.

The average listed price across the dataset was **$15,836**, for vehicles averaging **11.9 years old** with **172,270 km (~107,000 miles)** on the odometer.

Because all listings fall within a single month rather than a multi-year span, a true before/after pandemic comparison isn't possible from this file alone — so the project is deliberately framed as a detailed snapshot of one unusual moment, using vehicle model year (rather than posting date) as the time-related dimension of interest.

## Data Preparation

- **Cleaning:** Of 426,880 raw rows, price was restricted to a plausible $500–$150,000 range, rows with missing or invalid model years were dropped, and odometer readings under 100 or over 350,000 miles were flagged and nulled (row retained) rather than deleted outright. This left 383,405 cleaned rows.
- **Deduplication:** Dealers frequently cross-post the same physical vehicle to dozens of regional Craigslist pages under the same VIN — some VINs appeared 200+ times in the raw data. Filtering to one row per unique VIN (plus listings with no VIN, which can't be deduplicated) produced **251,092 records** representing real, distinct vehicles. Only about 61% of listings included a VIN at all.
- **Derived fields:** vehicle age, odometer in kilometers, ordered age/price/mileage buckets, a cleaned manufacturer name, numeric cylinder count, EV/hybrid and clean-title flags, price-per-distance ratios, and posting week/month.
- **Note:** a small (~0.5%) discrepancy in total vehicle count appears between tools (251,092 in Excel/Power BI vs. 249,758 in Tableau) due to minor differences in how each tool's filter context was applied — this doesn't meaningfully affect any finding below.

## Key Findings

| Area | Result |
| --- | --- |
| Overall average price | **$15,836** |
| Average vehicle age | **11.9 years** |
| Average odometer | **172,270 km (~107,000 mi)** |
| Price, 0–2 years old | **$35,138** |
| Price, 16–20 years old | **$7,137** (an 80% decline from 0–2 yrs) |
| Price, 20+ years old | **$11,158** (a notable uptick — likely collector/specialty vehicles) |
| Price, under 25,000 km | **~$30,000** |
| Price, over 200,000 km | **~$9,000** |
| Highest-price body types | Pickup trucks (~$25,000), full-size trucks (~$22,000) |
| Lowest-price body type | Mini-vans (~$9,000) |
| Highest-price brand (top 10 by volume) | Ram (~$27,000) |
| Lowest-price brand (top 10 by volume) | Honda (~$10,000) |
| Highest-price fuel type | Diesel (~$30,000 — reflects heavy-duty truck concentration) |
| Cheapest fuel types | Gas and hybrid (~$14,000–$15,000) |
| Lien vs. clean title | Lien ~$22,000 vs. clean title ~$16,000 (confounded by lien vehicles skewing newer/financed) |
| Price range by state | **$10,988 to $23,358** |

### Depreciation & Mileage
Average price falls sharply with age — an 80% decline from the newest to the 16–20 year bracket — but the curve isn't purely monotonic: vehicles over 20 years old average *more* than the 16–20 year bracket, likely reflecting collector and specialty vehicles that hold value once they age out of the "just an old car" category. Mileage, by contrast, behaves as a cleaner, purely linear value-destroyer with no late uptick.

### Geography
Building the geographic view surfaced a real data/tooling issue worth documenting: 2-letter state codes are ambiguous to mapping software (e.g. "CA" can resolve to Canada, "GA" to the country Georgia), which caused Power BI to mis-place 2 states and Tableau to initially fail to geocode all 51 values until the country context was explicitly set to United States — a small but instructive lesson in real-world geospatial data cleaning.

## The Pandemic Question: Does This Data Show COVID-19's Fingerprint?

Using vehicle model year as a proxy for "how new is the used-car supply," a striking pattern emerges in the 2010–2021 model-year cohorts: prices rise steadily with model year (roughly $10,000 for 2010 models up to roughly $38,000 for 2020 models), but listing *volume* doesn't rise to match — it inverts. Listings per model year climb through the mid-2010s, then drop sharply for 2019–2021 models. Specifically, average price for 2020-model vehicles jumped to **$38,513** (from $32,457 for 2019 models) while the number of available listings *fell* from 9,667 to 6,575 over the same one-year jump — prices up, supply down, in the same breath.

This lines up with several well-documented external causes of the 2021 used-car price spike: new-vehicle production constrained by the global semiconductor shortage, rental car companies unable to quickly restock fleets sold off in 2020, and elevated consumer demand for personal vehicles.

**Important caveat:** this is correlational, in-file evidence consistent with a well-documented external event — not proof of causation from this dataset alone, since there's no earlier snapshot in this file to compare against. A rigorous before/after comparison would require pairing this dataset with an external time series, such as the Manheim Used Vehicle Value Index or the U.S. BLS "Used Cars and Trucks" CPI component. That comparison was intentionally scoped out of this project but is a natural next step.

## Limitations

- **Single time snapshot:** all listings fall within one month (April–May 2021), so no true before/after pandemic comparison is possible within this file alone.
- **Incomplete deduplication:** only ~61% of listings included a VIN; non-VIN listings couldn't be checked for duplication and are included as-is.
- **Missing categorical data:** roughly 10,600 listings have no manufacturer and about 72,000 have no body type recorded — normal for scraped classified-ad data, but it slightly understates volumes in brand- and body-type-based views.
- **Self-reported data:** Craigslist listings are entered by individual sellers and dealers with no verification, so fields like mileage, condition, and title status reflect what was typed into the listing, not an independently audited record.
- **Minor cross-tool count variance:** total vehicle counts differ by ~0.5% between Excel/Power BI and Tableau due to filter-context differences, not a data error.

## Deliverables

| File | Description |
| --- | --- |
| `Used Cars Analysis.xlsx` | 8 PivotTables/PivotCharts, 4 slicers, and a KPI dashboard sheet |
| `Used Cars Analysis.pbix` | Equivalent interactive Power BI dashboard, including a U.S. map |
| `Tableau used cars analysis.twb` | 8-chart Tableau dashboard with filters and KPI tiles |
| `sql_functions_and_joins_reference.sql` | Reference of common SQL functions and all join types, applied to this dataset's schema |
| `Used Car Market Analysis Report.docx` | Full written report this README is based on |

## Conclusion

Vehicle price in this dataset behaves largely as economic intuition would predict — falling with age and mileage, and varying by body type, brand, and fuel category in ways that track real-world vehicle utility and cost. The most analytically interesting result isn't in any single chart but in the interaction between two of them: newer model-year vehicles were both scarcer and more expensive than the broader trend predicted, a pattern consistent with the documented used-car shortage of 2021.
