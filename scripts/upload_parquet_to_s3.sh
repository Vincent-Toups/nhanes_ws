#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARQUET_DIR="${ROOT_DIR}/data/parquet/2013-2014"

: "${NHANES_S3_BUCKET:?Set NHANES_S3_BUCKET to an S3 bucket name}"
S3_PREFIX="${NHANES_S3_PREFIX:-nhanes/2013-2014/parquet}"

for parquet_file in "${PARQUET_DIR}"/*.parquet; do
  table_name="$(basename "${parquet_file}" .parquet)"
  aws s3 cp "${parquet_file}" \
    "s3://${NHANES_S3_BUCKET}/${S3_PREFIX}/${table_name}/${table_name}.parquet" \
    --only-show-errors
done
aws s3 cp "${PARQUET_DIR}/schema_manifest.json" \
  "s3://${NHANES_S3_BUCKET}/${S3_PREFIX}/schema_manifest.json" \
  --only-show-errors

echo "Uploaded ${PARQUET_DIR} to s3://${NHANES_S3_BUCKET}/${S3_PREFIX}/"
