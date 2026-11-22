import csv
from pathlib import Path

path = Path("seeds/retail_sales.csv")
with path.open(newline="") as f:
    reader = csv.DictReader(f)
    fields = reader.fieldnames
    rows = list(reader)

seen = set()
corrected = []
for row in rows:
    if row["transaction_id"] in seen:
        continue
    seen.add(row["transaction_id"])
    if row["transaction_id"] == "TXN1002" and row["sale_status"].lower() == "completed":
        row["amount"] = f'{float(row["quantity"]) * float(row["unit_price"]):.2f}'
    corrected.append(row)

with path.open("w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()
    writer.writerows(corrected)

print(f"Rows after correction: {len(corrected)}")
row = next(r for r in corrected if r["transaction_id"] == "TXN1002")
print(f'TXN1002 corrected amount: {row["amount"]}')
