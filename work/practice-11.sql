-- Practice 11: four core tasks, one optional task, then Assignment 2 studio.
-- Read docs/practices-11-12.md and docs/practices-11-12-sql-guide.md.
-- Write each report below; this starter contains prompts, not completed solutions.
-- Save actual results, prediction, candidate DDL, paired plans and explanation under work/.
SET TIME ZONE 'UTC';

-- Suggested minutes 0-10: explore the LSM simulator or review the Lecture 6 examples independently.
-- You may also follow the live demonstration when available; attendance is not required.
-- Save one observation about versions/flushes and one about the missing-key read trace.
-- Model counters are not PostgreSQL query measurements.

-- P11-1 CORE, 10-22: programme 1 requirements; one main SELECT.
-- Output: student_id, full_name, has_any_pass, has_all_pass; order by student_id.
-- A required course passes if ANY attempt has grade >= 60. NULL does not pass.
-- Repeated passes cannot replace a missing course; unrelated courses do not count.
-- Explain none as NOT has_any_pass. Rerun for empty-requirements programme 10.
-- Choose a candidate for attempts lookups. Measure programme 1 WITHOUT and WITH it.
-- Keep the query/parameters fixed; compare complete results and EXPLAIN (ANALYZE, BUFFERS).

-- P11-2 CORE, 22-35: conflicting booking pairs in room 1.
-- Both bookings overlap [2026-10-20 09:00+00, 2026-10-20 12:00+00) and one another.
-- Output: room_id, booking_a, booking_b, overlap_start, overlap_end.
-- Require booking_a < booking_b; order by room_id, booking_a, booking_b.
-- Return the full booking intersection, not one clipped to the report window.
-- Touching endpoints do not conflict. Reset indexes; choose and test one candidate.

-- P11-3 CORE, 35-47: available rooms of capacity >= 30.
-- No overlap with [2026-10-20 10:00+00, 2026-10-20 11:00+00).
-- Output: room_id, room_name, capacity; order by room_id; keep never-booked rooms.
-- Correlate NOT EXISTS to the room. Check adjacent endpoints and too-small rooms.
-- Reset indexes, choose a candidate, measure identical query WITHOUT/WITH it.
-- Explain what might change if the index used the other time bound.

-- P11-4 CORE, 47-60: two equivalent pages of 20 bookings.
-- Output: booking_id, room_id, starts_at, ends_at.
-- Order by starts_at DESC, booking_id DESC in BOTH variants.
-- Variant A: OFFSET 100000. Variant B: strict continuation after the supplied cursor.
-- In container psql, run: \i /course/sql/practices-11-12-cursor.sql
-- Cursor lookup is setup, excluded from the measured keyset query.
-- Reset indexes; measure both variants, add your ordering candidate, measure both again.
-- Verify all 20 rows match in order. Compare rewrites with indexes fixed.
-- Partial outline: copy into TWO separately measured SELECTs, then complete the bracketed parts.
-- SELECT booking_id, room_id, starts_at, ends_at
-- FROM advanced_lab.bookings
-- [keyset variant only: complete the strict cursor predicate]
-- ORDER BY [complete the total descending order]
-- [complete the limit and, for OFFSET only, the offset];
-- Use SQL-guide section 12 for separate value/multiplicity and order checks.
-- Exit: why do adjacent bookings not conflict, and what index condition can narrow the overlap search?

-- P11-5 OPTIONAL: lower(full_name) = 'olena bondar'.
-- Output: student_id, full_name; order by student_id.
-- Keep the predicate fixed. Compare an ordinary name index and an expression index
-- independently against baseline; save plans, unchanged results and sizes.

-- Resets and sizes are container psql commands, not SQL for pgAdmin's Query Tool:
-- \i /course/sql/practices-11-12-reset-indexes.sql
-- \i /course/sql/practices-11-12-sizes.sql
-- Full advanced_lab recovery, only after saving work:
-- \i /course/sql/practices-11-12-checkpoint.sql
-- Minutes 60-80: Assignment 2 studio.
