-- Run once in Athena. Set the query-results S3 location in the workgroup first.
CREATE DATABASE IF NOT EXISTS nhanes_2013_2014;

-- After an AWS Glue crawler has cataloged s3://<bucket>/nhanes/2013-2014/parquet/,
-- select nhanes_2013_2014 in the Athena query editor and run examples like:

-- Confirm table sizes.
SELECT COUNT(*) AS participants
FROM nhanes_2013_2014.demo_h;

-- Join participant-level demographics, body measures, blood pressure, and labs.
SELECT
    d.seqn,
    d.ridageyr,
    d.riagendr,
    b.bmxwaist,
    p.bpxsy1,
    g.lbxgh,
    h.lbdhdd
FROM nhanes_2013_2014.demo_h d
LEFT JOIN nhanes_2013_2014.bmx_h b ON d.seqn = b.seqn
LEFT JOIN nhanes_2013_2014.bpx_h p ON d.seqn = p.seqn
LEFT JOIN nhanes_2013_2014.ghb_h g ON d.seqn = g.seqn
LEFT JOIN nhanes_2013_2014.hdl_h h ON d.seqn = h.seqn
LIMIT 25;

-- Sensor data is intentionally one-to-many: several daily observations per participant.
SELECT
    d.seqn,
    d.ridageyr,
    s.paxdayh,
    s.paxvmd,
    s.paxwwmd,
    s.paxswmd,
    s.paxnwmd
FROM nhanes_2013_2014.paxday_h s
JOIN nhanes_2013_2014.demo_h d ON d.seqn = s.seqn
ORDER BY d.seqn, s.paxdayh
LIMIT 100;

-- Dietary recall is also participant-day data; retain day 1 and day 2 as rows.
SELECT
    d.seqn,
    r.dr1day,
    r.dr1tkcal,
    r.dr1tprot,
    r.dr1tcarb,
    r.dr1ttfat
FROM nhanes_2013_2014.dr1tot_h r
JOIN nhanes_2013_2014.demo_h d ON d.seqn = r.seqn
LIMIT 25;
