MERGE INTO retail_orders AS target
USING dedup_updates AS source
ON target.order_id = source.order_id

WHEN MATCHED THEN
  UPDATE SET
    target.customer_id = source.customer_id,
    target.product = source.product,
    target.amount = source.amount,
    target.order_date = source.order_date

WHEN NOT MATCHED THEN
  INSERT (order_id, customer_id, product, amount, order_date)
  VALUES (
    source.order_id,
    source.customer_id,
    source.product,
    source.amount,
    source.order_date
  );
