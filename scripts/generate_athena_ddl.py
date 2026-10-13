#!/usr/bin/env python3
"""Generate explicit Athena external-table DDL from Parquet schemas."""

from __future__ import annotations

import argparse
from pathlib import Path

import pyarrow.parquet as pq


def athena_type(field) -> str:
    arrow_type = field.type
    if arrow_type.is_boolean:
        return "boolean"
    if arrow_type.is_integer:
        return "bigint"
    if arrow_type.is_floating:
        return "double"
    if arrow_type.is_timestamp:
        return "timestamp"
    if arrow_type.is_date:
        return "date"
    return "string"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", type=Path, default=Path("data/parquet/2013-2014"))
    parser.add_argument("--database", default="nhanes_2013_2014")
    parser.add_argument("--s3-prefix", required=True, help="s3://bucket/prefix without trailing slash")
    args = parser.parse_args()

    print(f"CREATE DATABASE IF NOT EXISTS {args.database};\n")
    for parquet_path in sorted(args.input_dir.glob("*.parquet")):
        table = parquet_path.stem
        schema = pq.read_schema(parquet_path)
        columns = ",\n".join(
            f"    {field.name} {athena_type(field)}" for field in schema
        )
        print(
            f"CREATE EXTERNAL TABLE IF NOT EXISTS {args.database}.{table} (\n"
            f"{columns}\n"
            ")\n"
            "STORED AS PARQUET\n"
            f"LOCATION '{args.s3_prefix}/{table}/';\n"
        )


if __name__ == "__main__":
    main()
