# Parquet, S3, and Athena objective

The first AWS objective is:

> Convert the NHANES 2013–2014 XPT source tables to Parquet, place the
> independent tables in Amazon S3, catalog them with AWS Glue, and query them
> with Amazon Athena using `SEQN` as the participant join key.

Amazon Athena is the SQL-on-S3 service for this exercise. Athena uses the AWS
Glue Data Catalog for table and column metadata. The XPT-to-Parquet conversion
already carries types forward, so type inference is not required. We register
those known Parquet schemas explicitly with Athena/Glue.

## Local conversion

Install the conversion dependencies in a virtual environment, then run:

```bash
python3 -m pip install -r requirements.txt
python3 scripts/convert_xpt_to_parquet.py
```

The output is `data/parquet/2013-2014/`, with one Snappy-compressed Parquet
file per XPT input and a `schema_manifest.json`. Column names are normalized
to lower case, so `SEQN` becomes `seqn` for Athena SQL.

Generate explicit Athena DDL from the Parquet schemas after conversion:

```bash
python3 scripts/generate_athena_ddl.py \
  --s3-prefix s3://my-workshop-bucket/nhanes/2013-2014/parquet \
  > athena/generated_tables.sql
```

Upload each Parquet file under its own table directory, as expected by the
generated DDL:

```text
s3://my-workshop-bucket/nhanes/2013-2014/parquet/demo_h/demo_h.parquet
s3://my-workshop-bucket/nhanes/2013-2014/parquet/bmx_h/bmx_h.parquet
```

## S3 and Athena

Set the bucket name and upload:

```bash
export NHANES_S3_BUCKET=my-workshop-bucket
export NHANES_S3_PREFIX=nhanes/2013-2014/parquet
./scripts/upload_parquet_to_s3.sh
```

In AWS:

1. Create or choose an Athena workgroup and configure an S3 query-results
   location, such as `s3://my-workshop-bucket/athena-results/`.
2. Create the `nhanes_2013_2014` database in Athena.
3. Run the generated `athena/generated_tables.sql` in Athena.
4. Run the examples in [`athena/queries.sql`](athena/queries.sql).

An AWS Glue crawler is an optional shortcut for exploratory work. It scans the
Parquet files and populates the same catalog, but it is not needed for this
pipeline and gives us less control over schema drift and table locations.

Do not make a single flattened table at this stage. `DEMO_H`, `BMX_H`, and
most laboratory files are approximately participant-level, while `PAXDAY_H`
and dietary recall tables are one-to-many participant-day data. Keeping each
source table separate makes cardinality and missingness visible.

## Expected learner outcome

The learner should be able to explain the complete path:

`XPT → Parquet → S3 → Glue Data Catalog → Athena SQL`

and write a query that joins participant-level measurements while separately
aggregating the sensor and dietary tables before joining them back to the
participant-level view.
