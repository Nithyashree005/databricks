SELECT 'BEFORE MERGE' AS state, order_id, amount
FROM retail_orders VERSION AS OF 0
WHERE order_id = 'ORD002'

UNION ALL

SELECT 'AFTER MERGE' AS state, order_id, amount
FROM retail_orders VERSION AS OF 1
WHERE order_id = 'ORD002';
