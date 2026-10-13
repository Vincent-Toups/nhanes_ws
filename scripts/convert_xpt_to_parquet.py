#!/usr/bin/env python3
"""Convert NHANES SAS transport files to independent Parquet tables."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import pandas as pd


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=Path("data/raw/2013-2014"),
        help="Directory containing .xpt files",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("data/parquet/2013-2014"),
        help="Directory for Parquet files",
    )
    return parser.parse_args()


def normalize_object_columns(frame: pd.DataFrame) -> pd.DataFrame:
    """Decode SAS byte strings and use stable lower-case column names."""
    frame.columns = [str(column).strip().lower() for column in frame.columns]
    for column in frame.select_dtypes(include=["object"]).columns:
        frame[column] = frame[column].map(
            lambda value: value.decode("utf-8", errors="replace").strip()
            if isinstance(value, bytes)
            else value
        )
    return frame


def main() -> None:
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    xpt_files = sorted(args.input_dir.glob("*.xpt"))
    if not xpt_files:
        raise SystemExit(f"No XPT files found in {args.input_dir}")

    manifest = []
    for xpt_path in xpt_files:
        print(f"Reading {xpt_path.name}")
        frame = normalize_object_columns(pd.read_sas(xpt_path, format="xport"))
        parquet_path = args.output_dir / f"{xpt_path.stem.lower()}.parquet"
        frame.to_parquet(parquet_path, index=False, compression="snappy")
        entry = {
            "source": xpt_path.name,
            "output": parquet_path.name,
            "rows": len(frame),
            "columns": len(frame.columns),
            "has_seqn": "seqn" in frame.columns,
            "schema": {column: str(dtype) for column, dtype in frame.dtypes.items()},
        }
        manifest.append(entry)
        print(f"  -> {parquet_path} ({len(frame):,} rows, {len(frame.columns)} columns)")

    (args.output_dir / "schema_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote {len(manifest)} Parquet tables and schema_manifest.json")


if __name__ == "__main__":
    main()
