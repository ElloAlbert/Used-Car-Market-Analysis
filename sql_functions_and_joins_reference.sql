-- ================================================================
-- SQL FUNCTIONS & JOINS REFERENCE
-- Used Cars Analysis Project (Craigslist "Used Cars" dataset)
-- ================================================================
-- Assumes a `vehicles` table loaded from vehicles_clean.csv, with
-- columns matching the cleaned file: id, price_usd, manufacturer_clean,
-- type, state, fuel, title_status, odometer_km, car_age, age_bucket,
-- year, posting_date, vin, is_primary_listing, etc.
--
-- Syntax below is written in standard/MySQL-flavored SQL. Notes call
-- out where SQLite, PostgreSQL, or SQL Server differ.
-- Written as a reference, not executed against a live database.
-- ================================================================


-- ================================================================
-- SECTION 1: AGGREGATE FUNCTIONS
-- ================================================================
-- COUNT, SUM, AVG, MIN, MAX — the core of almost every analytical query.

-- How many primary (deduplicated) listings are there?
SELECT COUNT(*) AS total_vehicles
FROM vehicles
WHERE is_primary_listing = 'Yes';

-- Average, min, and max price across the whole dataset
SELECT
    ROUND(AVG(price_usd), 0) AS avg_price,
    MIN(price_usd)           AS min_price,
    MAX(price_usd)           AS max_price
FROM vehicles
WHERE is_primary_listing = 'Yes';

-- Total combined value of all listed vehicles
SELECT SUM(price_usd) AS total_market_value
FROM vehicles
WHERE is_primary_listing = 'Yes';


-- ================================================================
-- SECTION 2: GROUP BY / HAVING
-- ================================================================
-- GROUP BY collapses rows into categories; HAVING filters on the
-- aggregated result (WHERE can't filter on an aggregate directly).

-- Average price and listing count per manufacturer
SELECT
    manufacturer_clean,
    COUNT(*)                 AS listings,
    ROUND(AVG(price_usd), 0) AS avg_price
FROM vehicles
WHERE is_primary_listing = 'Yes'
GROUP BY manufacturer_clean
ORDER BY avg_price DESC;

-- Only manufacturers with a meaningful sample size (HAVING filters the group, not the row)
SELECT
    manufacturer_clean,
    COUNT(*)                 AS listings,
    ROUND(AVG(price_usd), 0) AS avg_price
FROM vehicles
WHERE is_primary_listing = 'Yes'
GROUP BY manufacturer_clean
HAVING COUNT(*) >= 1000
ORDER BY avg_price DESC;


-- ================================================================
-- SECTION 3: STRING FUNCTIONS
-- ================================================================

-- UPPER / LOWER — normalize text for display or comparison
SELECT DISTINCT UPPER(state) AS state_upper
FROM vehicles;

-- CONCAT — build a readable label from multiple columns
SELECT
    CONCAT(manufacturer_clean, ' ', model, ' (', year, ')') AS vehicle_label,
    price_usd
FROM vehicles
LIMIT 10;

-- TRIM — strip stray whitespace (common in scraped/Craigslist text data)
SELECT DISTINCT TRIM(type) AS body_type
FROM vehicles;

-- SUBSTRING / LEFT — pull a fixed-length piece out of a string (e.g. first 3 VIN chars = manufacturer's World Manufacturer Identifier)
SELECT
    vin,
    SUBSTRING(vin, 1, 3) AS wmi_code
FROM vehicles
WHERE vin IS NOT NULL
LIMIT 10;


-- ================================================================
-- SECTION 4: DATE FUNCTIONS
-- ================================================================

-- EXTRACT / YEAR / MONTH — pull date parts out for grouping
SELECT
    EXTRACT(MONTH FROM posting_date) AS posting_month,
    COUNT(*)                         AS listings
FROM vehicles
GROUP BY EXTRACT(MONTH FROM posting_date)
ORDER BY posting_month;

-- DATEDIFF — days between two dates (MySQL syntax; Postgres uses posting_date - other_date)
SELECT
    id,
    DATEDIFF(CURRENT_DATE, posting_date) AS days_since_posted
FROM vehicles
LIMIT 10;


-- ================================================================
-- SECTION 5: CASE WHEN (conditional logic)
-- ================================================================
-- Recreates a bucket column on the fly, same idea as the age_bucket /
-- price_bucket columns already built into vehicles_clean.csv.

SELECT
    id,
    price_usd,
    CASE
        WHEN price_usd < 5000  THEN 'Budget'
        WHEN price_usd < 15000 THEN 'Mid-range'
        WHEN price_usd < 30000 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_tier
FROM vehicles
WHERE is_primary_listing = 'Yes';


-- ================================================================
-- SECTION 6: NULL HANDLING
-- ================================================================

-- COALESCE — substitute a default when a value is missing
SELECT
    id,
    COALESCE(manufacturer_clean, 'Unknown') AS manufacturer_display
FROM vehicles;

-- IS NULL / IS NOT NULL — filtering for missing vs. present values
SELECT COUNT(*) AS missing_body_type
FROM vehicles
WHERE type IS NULL;


-- ================================================================
-- SECTION 7: SUBQUERIES & CTEs
-- ================================================================

-- Subquery: vehicles priced above the overall average
SELECT id, manufacturer_clean, price_usd
FROM vehicles
WHERE price_usd > (
    SELECT AVG(price_usd) FROM vehicles WHERE is_primary_listing = 'Yes'
);

-- CTE (WITH clause): same idea, but more readable for multi-step logic
WITH manufacturer_avg AS (
    SELECT manufacturer_clean, AVG(price_usd) AS avg_price
    FROM vehicles
    WHERE is_primary_listing = 'Yes'
    GROUP BY manufacturer_clean
)
SELECT v.id, v.manufacturer_clean, v.price_usd, m.avg_price
FROM vehicles v
JOIN manufacturer_avg m ON v.manufacturer_clean = m.manufacturer_clean
WHERE v.price_usd > m.avg_price;


-- ================================================================
-- SECTION 8: WINDOW FUNCTIONS
-- ================================================================
-- Unlike GROUP BY, window functions keep every row while adding
-- calculated context from a group of related rows ("window").

-- ROW_NUMBER — assign a unique rank per manufacturer group, ordered by price
SELECT
    id,
    manufacturer_clean,
    price_usd,
    ROW_NUMBER() OVER (PARTITION BY manufacturer_clean ORDER BY price_usd DESC) AS price_rank
FROM vehicles
WHERE is_primary_listing = 'Yes';

-- RANK — like ROW_NUMBER but ties share the same rank (with a gap after)
SELECT
    id,
    manufacturer_clean,
    price_usd,
    RANK() OVER (PARTITION BY manufacturer_clean ORDER BY price_usd DESC) AS price_rank
FROM vehicles
WHERE is_primary_listing = 'Yes';

-- Running average price by posting date (illustrates a moving/cumulative window)
SELECT
    posting_date,
    price_usd,
    AVG(price_usd) OVER (ORDER BY posting_date ROWS BETWEEN 100 PRECEDING AND CURRENT ROW) AS rolling_avg_price
FROM vehicles
WHERE is_primary_listing = 'Yes';


-- ================================================================
-- SECTION 9: JOINS
-- ================================================================
-- The vehicles table alone is flat (single Craigslist scrape), so a
-- small lookup table is created here to demonstrate joins meaningfully:
-- mapping each state abbreviation to a US Census region/division.

CREATE TABLE state_region (
    state  VARCHAR(2)  PRIMARY KEY,   -- e.g. 'ca', 'ny', 'tx'
    region VARCHAR(20)                -- e.g. 'West', 'Northeast', 'South'
);

INSERT INTO state_region (state, region) VALUES
    ('ca', 'West'), ('wa', 'West'), ('or', 'West'),
    ('ny', 'Northeast'), ('ma', 'Northeast'), ('nj', 'Northeast'),
    ('tx', 'South'), ('fl', 'South'), ('ga', 'South'),
    ('il', 'Midwest'), ('oh', 'Midwest'), ('mi', 'Midwest');
    -- (etc. — full 50-state list would continue here)

-- ---------------- INNER JOIN ----------------
-- Only rows with a match on BOTH sides. A vehicle whose state isn't in
-- state_region (e.g. a typo, or a state not yet added above) is dropped.
SELECT v.id, v.state, r.region, v.price_usd
FROM vehicles v
INNER JOIN state_region r ON v.state = r.state
WHERE v.is_primary_listing = 'Yes';

-- ---------------- LEFT JOIN ----------------
-- Keeps every vehicle row regardless of match; unmatched states get NULL
-- for region. Best default choice when the left table is the "main" data
-- and you don't want to silently drop rows.
SELECT v.id, v.state, r.region, v.price_usd
FROM vehicles v
LEFT JOIN state_region r ON v.state = r.state
WHERE v.is_primary_listing = 'Yes';

-- ---------------- RIGHT JOIN ----------------
-- Mirror of LEFT JOIN: keeps every row from state_region, even a region
-- with no matching vehicles. Rare in practice — usually just flip the
-- table order and use LEFT JOIN instead (not supported at all in SQLite).
SELECT v.id, v.state, r.region, v.price_usd
FROM vehicles v
RIGHT JOIN state_region r ON v.state = r.state;

-- ---------------- FULL OUTER JOIN ----------------
-- Keeps unmatched rows from BOTH sides. Not supported in MySQL or SQLite —
-- emulate with a LEFT JOIN UNION a RIGHT JOIN (or UNION ALL + NOT EXISTS
-- to avoid duplicating the matched rows):
SELECT v.id, v.state, r.region, v.price_usd
FROM vehicles v
LEFT JOIN state_region r ON v.state = r.state
UNION
SELECT v.id, v.state, r.region, v.price_usd
FROM vehicles v
RIGHT JOIN state_region r ON v.state = r.state;

-- ---------------- CROSS JOIN ----------------
-- Every row from the left paired with every row from the right (cartesian
-- product) — no ON condition. Useful for generating all combinations,
-- e.g. every body type against every price tier, to left-join analysis
-- results onto later.
SELECT DISTINCT t.type, p.price_tier
FROM (SELECT DISTINCT type FROM vehicles) t
CROSS JOIN (SELECT DISTINCT price_bucket AS price_tier FROM vehicles) p;

-- ---------------- SELF JOIN ----------------
-- Joins a table to itself — typically to compare rows within the same
-- table. Example: find vehicles priced above their own manufacturer's
-- average (same result as the CTE in Section 7, done as a self join instead).
SELECT
    v1.id,
    v1.manufacturer_clean,
    v1.price_usd,
    v2.avg_mfr_price
FROM vehicles v1
INNER JOIN (
    SELECT manufacturer_clean, AVG(price_usd) AS avg_mfr_price
    FROM vehicles
    WHERE is_primary_listing = 'Yes'
    GROUP BY manufacturer_clean
) v2 ON v1.manufacturer_clean = v2.manufacturer_clean
WHERE v1.price_usd > v2.avg_mfr_price;


-- ================================================================
-- QUICK REFERENCE: WHEN TO USE WHICH JOIN
-- ================================================================
-- INNER JOIN  : only rows that match in both tables (most common default)
-- LEFT JOIN   : keep everything from the main/left table, matched or not
-- RIGHT JOIN  : keep everything from the lookup/right table, matched or not
-- FULL OUTER  : keep everything from both, matched or not
-- CROSS JOIN  : every combination of both tables (no matching condition)
-- SELF JOIN   : a table joined to itself, to compare rows against each other
