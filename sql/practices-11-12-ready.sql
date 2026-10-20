\set ON_ERROR_STOP on
-- Read-only readiness for advanced_lab, independent of earlier practice schemas.
DO $$
BEGIN
    IF (SELECT count(*) FROM advanced_lab.programmes) <> 10
       OR (SELECT count(*) FROM advanced_lab.students) <> 10000
       OR (SELECT count(*) FROM advanced_lab.courses) <> 30
       OR (SELECT count(*) FROM advanced_lab.requirements) <> 27
       OR (SELECT count(*) FROM advanced_lab.attempts) <> 100000
       OR (SELECT count(*) FROM advanced_lab.rooms) <> 200
       OR (SELECT count(*) FROM advanced_lab.bookings) <> 200000
       OR (SELECT count(*) FROM advanced_lab.portal_events) <> 240000 THEN
        RAISE EXCEPTION 'Practice 11-12 fixture counts are incomplete; save work and consult your TA.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM advanced_lab.attempts
                   WHERE (attempt_id, student_id, course_id, grade) = (13, 1, 1, 20))
       OR NOT EXISTS (SELECT 1 FROM advanced_lab.attempts
                      WHERE (attempt_id, student_id, course_id, grade) = (14, 6, 4, 80))
       OR NOT EXISTS (SELECT 1 FROM advanced_lab.portal_events
                      WHERE (event_id, student_id, occurred_at, event_type) =
                            (25, 42, timestamptz '2026-03-01 01:31:30+00', 'view')) THEN
        RAISE EXCEPTION 'Practice 11-12 edge cases are not ready; apply migration 71. If it refuses, save work and consult your TA.';
    END IF;
END
$$;
SELECT 'Practice 11-12 data ready (migration 71)' AS result;
