-- DA-D3-301 — DATA QUALITY INCIDENT: MISSING CUSTOMER IDS AND REGIONS
-- Replace DAY3_USER01_DB with your assigned database (DAY3_USER01_DB ... DAY3_USER30_DB).
-- Run each CELL separately and in order. The raw table is never modified.

-- CELL 301.1 — Establish baseline before making changes
SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT_IF(customer_id IS NULL) AS MISSING_CUSTOMER_IDS,
    COUNT_IF(region IS NULL) AS MISSING_REGIONS,
    COUNT_IF(customer_id IS NULL AND region IS NULL) AS MISSING_BOTH
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_RAW;
-- Supplied-data baseline previously observed: 1,000 rows, 48 missing customer IDs, 40 missing regions.
-- MISSING_BOTH must be measured; do not assume the two issue groups are disjoint.

-- CELL 301.2 — Inspect records with either issue
SELECT *
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_RAW
WHERE customer_id IS NULL OR region IS NULL
ORDER BY transaction_id;

-- CELL 301.3 — Create clean output: both required fields are present
CREATE OR REPLACE TABLE DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_CLEAN AS
SELECT *
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_RAW
WHERE customer_id IS NOT NULL
  AND region IS NOT NULL;

-- CELL 301.4 — Quarantine records missing customer ID (includes records also missing region)
CREATE OR REPLACE TABLE DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_QUARANTINE_CUSTOMER AS
SELECT *
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_RAW
WHERE customer_id IS NULL;

-- CELL 301.5 — Quarantine records missing region only (customer ID is present)
-- This category is mutually exclusive with CUSTOMER quarantine, preventing double counting.
CREATE OR REPLACE TABLE DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_QUARANTINE_REGION AS
SELECT *
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_RAW
WHERE customer_id IS NOT NULL
  AND region IS NULL;

-- CELL 301.6 — Validate each output independently
SELECT 'RAW' AS DATASET, COUNT(*) AS ROW_COUNT
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_RAW
UNION ALL
SELECT 'CLEAN', COUNT(*) FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_CLEAN
UNION ALL
SELECT 'QUARANTINE_CUSTOMER', COUNT(*)
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_QUARANTINE_CUSTOMER
UNION ALL
SELECT 'QUARANTINE_REGION_ONLY', COUNT(*)
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_QUARANTINE_REGION;

-- CELL 301.7 — Reconciliation: clean + mutually exclusive quarantine groups must equal raw
SELECT
    (SELECT COUNT(*) FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_RAW) AS RAW_ROWS,
    (SELECT COUNT(*) FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_CLEAN)
    + (SELECT COUNT(*) FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_QUARANTINE_CUSTOMER)
    + (SELECT COUNT(*) FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_QUARANTINE_REGION) AS ACCOUNTED_ROWS;

-- CELL 301.8 — Confirm clean output has no missing customer IDs or regions
SELECT
    COUNT_IF(customer_id IS NULL) AS NULL_CUSTOMER_IDS,
    COUNT_IF(region IS NULL) AS NULL_REGIONS
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_CLEAN;
-- Expected: both values are zero.

-- CELL 301.9 — Preserve and investigate repeated transaction IDs
SELECT transaction_id, COUNT(*) AS RECORD_COUNT,
       COUNT(DISTINCT sale_date) AS DISTINCT_DATES,
       COUNT(DISTINCT store_id) AS DISTINCT_STORES,
       COUNT(DISTINCT product_id) AS DISTINCT_PRODUCTS
FROM DAY3_USER01_DB.RETAIL_LAB.RETAIL_SALES_RAW
GROUP BY transaction_id
HAVING COUNT(*) > 1
ORDER BY RECORD_COUNT DESC, transaction_id;
-- The observed repeated IDs have different business attributes. Do not delete by transaction_id alone.
-- Quarantine separates affected records; it does not repair missing values. Correct only from an authoritative source.
