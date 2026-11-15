# Snapshot profiling
print("===== SNAPSHOT QUALITY PROFILE =====")
print("Row count:", snapshot_df.count())
print("Distinct order IDs:", snapshot_df.select("order_id").distinct().count())

snapshot_df.select([
    F.sum(F.col(c).isNull().cast("int")).alias(c)
    for c in snapshot_df.columns
]).show()

snapshot_df.select(
    F.min("order_date").alias("min_date"),
    F.max("order_date").alias("max_date")
).show()


# Change-feed profiling
print("===== CHANGE FEED QUALITY PROFILE =====")
print("Row count:", change_df.count())
print("Distinct order IDs:", change_df.select("order_id").distinct().count())

change_df.select([
    F.sum(F.col(c).isNull().cast("int")).alias(c)
    for c in change_df.columns
]).show()

change_df.select(
    F.min("order_date").alias("min_date"),
    F.max("order_date").alias("max_date")
).show()


# Find duplicate business keys
print("===== DUPLICATE ORDER IDs IN CHANGE FEED =====")

change_df.groupBy("order_id") \
    .count() \
    .filter(F.col("count") > 1) \
    .show()
