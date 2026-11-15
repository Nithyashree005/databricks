# databricks
from pyspark.sql.types import StructType, StructField, StringType, DoubleType

# -------------------------
# ORDER SNAPSHOT
# -------------------------
snapshot_data = [
    ("ORD001", "CUST101", "Laptop",   65000.0, "2026-11-10"),
    ("ORD002", "CUST102", "Phone",    30000.0, "2026-11-10"),
    ("ORD003", "CUST103", "Tablet",   25000.0, "2026-11-11"),
    ("ORD004", "CUST104", "Monitor",  15000.0, "2026-11-11"),
    ("ORD005", None,      "Keyboard",  3000.0, "2026-11-12"),
    ("ORD006", "CUST106", "Mouse",     1500.0, "2026-11-12")
]

schema = StructType([
    StructField("order_id", StringType(), True),
    StructField("customer_id", StringType(), True),
    StructField("product", StringType(), True),
    StructField("amount", DoubleType(), True),
    StructField("order_date", StringType(), True)
])

snapshot_df = spark.createDataFrame(snapshot_data, schema)

# -------------------------
# CHANGE FEED
# -------------------------
change_data = [
    ("ORD002", "CUST102", "Phone",   32000.0, "2026-11-13", "2026-11-13 09:00:00"),
    ("ORD002", "CUST102", "Phone",   35000.0, "2026-11-13", "2026-11-13 11:00:00"),
    ("ORD004", "CUST104", "Monitor", 16000.0, "2026-11-13", "2026-11-13 10:00:00"),
    ("ORD007", "CUST107", "Headset",  5000.0, "2026-11-14", "2026-11-14 08:00:00"),
    ("ORD008", None,      "Printer", 12000.0, "2026-11-14", "2026-11-14 09:00:00")
]

change_schema = StructType([
    StructField("order_id", StringType(), True),
    StructField("customer_id", StringType(), True),
    StructField("product", StringType(), True),
    StructField("amount", DoubleType(), True),
    StructField("order_date", StringType(), True),
    StructField("update_ts", StringType(), True)
])

change_df = spark.createDataFrame(change_data, change_schema)

print("Snapshot:")
snapshot_df.show()

print("Change Feed:")
change_df.show()
