from pathlib import Path
import csv
import logging

import pendulum
from airflow.sdk import dag, task

PROJECT_INCLUDE = Path("/usr/local/airflow/include")

# Intentional PS1 fault: participants should identify and correct this filename.
INPUT_FILE = PROJECT_INCLUDE / "ps1_data" / "retail_sales_missing.csv"

# Writable lab output path used during validation. This is temporary container storage.
OUTPUT_FILE = Path("/tmp/validated_sales_summary.csv")


@dag(
    dag_id="ps1_retail_sales_recovery",
    description="PS1: Diagnose and recover a retail-sales input-path failure",
    start_date=pendulum.datetime(2026, 10, 1, tz="UTC"),
    schedule=None,
    catchup=False,
    tags=["day5", "ps1", "recovery"],
)
def ps1_retail_sales_recovery():

    @task
    def validate_input():
        logging.info("Checking retail-sales input: %s", INPUT_FILE)

        if not INPUT_FILE.exists():
            raise FileNotFoundError(
                f"Retail-sales input file not found: {INPUT_FILE}"
            )

        with INPUT_FILE.open("r", newline="", encoding="utf-8") as file:
            rows = list(csv.DictReader(file))

        if not rows:
            raise ValueError("Retail-sales input contains no data rows.")

        logging.info("Input validation passed. Records found: %s", len(rows))
        return rows

    @task
    def generate_summary(rows):
        total_amount = sum(
            int(row["quantity"]) * float(row["unit_price"])
            for row in rows
        )

        summary = {
            "record_count": len(rows),
            "total_amount": round(total_amount, 2),
        }

        with OUTPUT_FILE.open("w", newline="", encoding="utf-8") as file:
            writer = csv.DictWriter(
                file,
                fieldnames=["record_count", "total_amount"],
            )
            writer.writeheader()
            writer.writerow(summary)

        logging.info("Summary generated: %s", OUTPUT_FILE)
        logging.info("Summary values: %s", summary)
        return summary

    rows = validate_input()
    generate_summary(rows)


ps1_retail_sales_recovery()
