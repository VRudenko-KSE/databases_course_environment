-- Practice 12: four core tasks, one optional task, then Assignment 2 studio.
-- Read docs/practices-11-12.md and docs/practices-11-12-sql-guide.md.
-- Write reports below; keep Practice 11 evidence and reset experimental indexes.
-- Save actual results, prediction, candidate DDL, paired plans and explanation under work/.
SET TIME ZONE 'UTC';

-- P12-1 CORE, 0-15: student 42 event gaps.
-- Input: [2026-03-01 00:00+00, 2026-03-08 00:00+00), all event types.
-- Output: event_id, occurred_at, previous_at, gap_minutes, starts_session.
-- Order by occurred_at, event_id. Calculate LAG, then gap and Boolean flag.
-- First row has NULL previous/gap and starts a session. Gap > 30 starts another.
-- Exactly 30 minutes stays; tied timestamps have zero gap. Reset at the report boundary.
-- Check event 25's 30-minute-30-second gap without truncating fractional minutes.
-- Choose an input/order candidate; compare identical query WITHOUT/WITH it.

-- P12-2 CORE, 15-30: students 1-100 inclusive, same reporting week.
-- Output: student_id, session_no, session_start, session_end, event_count, duration_minutes.
-- Order by student_id, session_no. Number each student's sessions from 1.
-- Stages: filter, LAG, integer start flag, running SUM with explicit ROWS frame, aggregate.
-- Partition each window by student; order each by occurred_at, event_id.
-- Single-event duration is zero; simultaneous events all count; no events means no row.
-- Reconcile event counts. Reset indexes; choose/test a candidate with this query fixed.
-- Extend your P12-1 predecessor/flag stages; add per-student partitions, numbering and aggregation.
-- Save a fresh plan pair for this complete report.

-- P12-3 CORE, 30-45: students 1-100, March active-day streaks of at least three dates.
-- March: [2026-03-01 00:00+00, 2026-04-01 00:00+00), all event types.
-- Output: student_id, streak_start, streak_end, active_days.
-- Order by student_id, streak_start. Return ALL qualifying streaks, not only the longest.
-- Deduplicate UTC dates before detecting gaps. Missing days break a streak.
-- Boundaries truncate streaks; repeated same-day events do not extend them.
-- Reset indexes; choose/test a candidate. Explain access versus deduplication/grouping work.

-- P12-4 CORE, 45-60: student 42 and 43 summaries; keep both students.
-- Output: student_id, march_events, latest_event_at; order by student_id.
-- One CTE reads student_id, occurred_at from the complete portal_events history.
-- Two correlated scalar subqueries reference it: March COUNT and all-history MAX.
-- Default, MATERIALIZED, NOT MATERIALIZED: change only the CTE declaration.
-- Measure all three with baseline indexes fixed and confirm identical results.
-- Empty COUNT is zero; missing latest timestamp is NULL.
-- Then hold NOT MATERIALIZED fixed, add a candidate index, and compare before/after.
-- Do not combine an index change with a rewrite and attribute the result to one cause.
-- Partial outline: complete both scalar subqueries, then copy only the CTE declaration for variants.
-- WITH event_source AS (
--     SELECT student_id, occurred_at FROM advanced_lab.portal_events
-- )
-- SELECT s.student_id,
--        ([complete the correlated March aggregate]) AS march_events,
--        ([complete the correlated all-history aggregate]) AS latest_event_at
-- FROM advanced_lab.students AS s
-- WHERE s.student_id IN (42, 43)
-- ORDER BY s.student_id;
-- Exit: why does filtering or indexing input not remove all window/CTE work,
-- and which plan observation supports your explanation?

-- P12-5 OPTIONAL: student 42 March observed daily counts and two averages in one SELECT.
-- Output: activity_date, event_count, seven_observation_average, seven_calendar_day_average.
-- Order by activity_date. Use ROWS 6 PRECEDING versus RANGE INTERVAL '6 days' PRECEDING,
-- each ending at CURRENT ROW; RANGE ordering uses the date as a midnight timestamp.
-- Do not generate missing dates or fill them with zero. Explain the different contributors.
-- Reset indexes; choose/test an input-access candidate with the same two-average query.

-- Container psql helpers:
-- \i /course/sql/practices-11-12-reset-indexes.sql
-- \i /course/sql/practices-11-12-sizes.sql
-- Full advanced_lab recovery, only after saving work:
-- \i /course/sql/practices-11-12-checkpoint.sql
-- Minutes 60-80: Assignment 2 studio; practice outputs remain separate.
