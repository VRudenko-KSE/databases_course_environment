-- Practice 10: four core tasks and one optional task.
-- Start from the constraint-only index baseline; preserve Practice 9 evidence.
SET TIME ZONE 'UTC';

-- P10-1 CORE: Latest 20 registrations in offering 101, timestamp DESC then ID DESC.
-- Measure the query WITHOUT the recommended index using EXPLAIN (ANALYZE, BUFFERS), then create it:
-- CREATE INDEX p10_recent ON index_lab.enrolments
-- (offering_id, registered_at DESC, enrolment_id DESC);
-- ANALYZE index_lab.enrolments;
-- Measure the identical query WITH it; compare results, plans, time and buffers.
-- Choose an alternative order and test it independently; restore baseline before each later task.

-- P10-2 CORE: Exactly three graded students per offering using ROW_NUMBER in a CTE.
-- Find a good index; measure WITHOUT it, CREATE it, measure WITH it, compare differences.
-- Explain the tied third place in offering 101.

-- P10-3 CORE: Complete March 1-7 calendar, daily counts and running total.
-- Include the quiet day. Find a good index; measure WITHOUT it, CREATE it, measure WITH it, compare differences.

-- P10-4 CORE: Recommend at most two indexes for the supplied portal workload.
-- Choose good indexes; measure reads WITHOUT them, CREATE them, measure WITH them, compare differences.
-- Repeat the paired scratch INSERT comparison with matching definitions and fresh historical baselines.
-- EXPLAIN ANALYZE executes the INSERT: rebuild scratch before EVERY attempt.
-- Write only to index_write.enrolments; never insert the batch into index_lab.enrolments.
-- Record the individual exit answer before the assignment studio.

-- P10-5 OPTIONAL: Repeat P9-2 unchanged; choose good plain and covering index designs.
-- Measure WITHOUT them, CREATE/test each independently, measure WITH, compare differences and sizes/heap fetches.
