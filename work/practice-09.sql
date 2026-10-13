-- Practice 9: four core tasks and one optional task.
-- See docs/practices-09-10.md. Save results and plans with task/configuration labels.
SET TIME ZONE 'UTC';

-- P9-1 CORE: All offerings, course title, semester, counts and average grade.
-- Keep empty offerings. Inspect the constraint indexes; run your query WITHOUT the added index.
-- Save EXPLAIN (ANALYZE, BUFFERS), then create the recommended index below.
-- CREATE INDEX p9_offering_report ON index_lab.enrolments (offering_id)
-- INCLUDE (enrolment_id, grade);
-- ANALYZE index_lab.enrolments;
-- Run the identical query WITH the index; compare results, plans, time and buffers.
-- Restore the index baseline before each later task.

-- P9-2 CORE: Student 42 transcript and tree trace.
-- Find and justify a good index; measure WITHOUT it, CREATE it, measure WITH it, compare differences.

-- P9-3 CORE: March daily registrations and cancellation count.
-- Use inclusive March 1 and exclusive April 1 in UTC.
-- Find a good index; measure WITHOUT it, CREATE it, measure WITH it, compare differences.

-- P9-4 CORE: Counts per offering for cancelled versus completed registrations.
-- Find a good index; measure both variants WITHOUT it, CREATE it, then measure both WITH it.
-- Compare differences and write the exit answer.

-- P9-5 OPTIONAL: March cancelled registrations; design suitable full/partial indexes.
-- Choose keys/predicate; measure WITHOUT, CREATE each independently, measure WITH, compare differences.
-- Also test the completed-status query with the partial candidate installed.
