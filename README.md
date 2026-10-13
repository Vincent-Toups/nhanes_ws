# NHANES multimodal starter data

This directory stages a small, reproducible subset of the public **NHANES
2013–2014** release for an AWS workshop. It is intentionally organized as
source files rather than a single flattened table so that the workshop can
demonstrate ingestion, cataloging, joins, and modality-specific processing.

## Selected modalities

| Modality | Files | Collection context |
|---|---|---|
| Demographics / survey design | `DEMO_H.xpt` | Household interview; weights, strata, PSU, demographics |
| Health questionnaire | `BPQ_H.xpt`, `PAQ_H.xpt`, `SMQ_H.xpt` | Self/proxy-reported health behaviors and conditions |
| Physical examination | `BMX_H.xpt`, `BPX_H.xpt`, `DXX_H.xpt` | Mobile Examination Center (MEC) measurements and DXA-derived values |
| Laboratory | `GHB_H.xpt`, `GLU_H.xpt`, `HDL_H.xpt` | MEC blood measurements |
| Dietary recall | `DR1TOT_H.xpt`, `DR2TOT_H.xpt` | Day 1 in-person and Day 2 telephone recalls |
| Sensor | `PAXHD_H.xpt`, `PAXDAY_H.xpt` | Seven-day wrist physical-activity monitor summaries |
| Metadata / documentation | HTML codebooks in `docs/2013-2014/` | Definitions, eligibility, missing values, methods |

Every data file can be linked with the participant identifier `SEQN`. The
files are not all one-to-one: dietary data are participant-day records, and
some examination/laboratory modules have narrower eligible populations.
That is useful workshop material—do not silently inner-join everything.

## Get the data

From this directory, run:

```bash
./scripts/download_nhanes.sh
```

The script downloads only the files listed in `manifest.csv`, saves them in
`data/raw/2013-2014/` and `docs/2013-2014/`, and writes `manifest.lock.csv`
with byte counts and SHA-256 hashes. Re-running it keeps existing files.

The source is the CDC/NCHS public NHANES 2013–2014 release. See `manifest.csv` for the
exact source URL and release metadata. NHANES data are subject to the CDC
data use terms; review the official documentation before redistributing or
using the data for analysis.

## Suggested workshop exercise

1. Upload `data/raw/2013-2014/` and `docs/2013-2014/` to separate S3 prefixes.
2. Crawl the XPT files with an appropriate tabular schema strategy.
3. Build a participant-level demographic/exam/lab feature view keyed by
   `SEQN`, retaining missingness indicators and source modality.
4. Keep `DR1TOT_H` and `DR2TOT_H` in a long participant-day table.
5. Use the HTML codebooks to enrich a data catalog and explain why sample
   weights (`WTINT2YR`, `WTMEC2YR`) and survey design fields matter.

The previously downloaded 2017–2018 files, if present under `data/raw/` or
`docs/`, are retained as legacy artifacts but are no longer part of the
manifest or workshop bundle.

This starter bundle is suitable for demonstrating multimodal integration; it
is not a complete NHANES release and should not be treated as a nationally
representative analytic extract without following NHANES analytic guidance.
