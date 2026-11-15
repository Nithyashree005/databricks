CREATE OR REPLACE TEMP VIEW dedup_updates AS
SELECT order_id, customer_id, product, amount, order_date, update_ts
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY update_ts DESC
           ) AS rn
    FROM change_feed
)
WHERE rn = 1;

SELECT * FROM dedup_updates ORDER BY order_id;
