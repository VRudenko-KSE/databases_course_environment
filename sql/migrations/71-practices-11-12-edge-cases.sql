\set ON_ERROR_STOP on
-- Safe upgrade of three canonical background rows. Reapplying is a no-op.
-- Refuse unexpected edits; save work and inspect them with your TA before recovery.
SET TIME ZONE 'UTC';
BEGIN;
DO $$
BEGIN
    PERFORM attempt_id FROM advanced_lab.attempts
    WHERE attempt_id IN (13, 14) ORDER BY attempt_id FOR UPDATE;
    PERFORM event_id FROM advanced_lab.portal_events WHERE event_id = 25 FOR UPDATE;

    -- Validate EVERY target before changing any row. IDs are identities, not chronology.
    IF NOT EXISTS (
        SELECT 1 FROM advanced_lab.attempts WHERE attempt_id = 13
        AND (student_id, course_id, grade) IN ((1050, 12, 91), (1, 1, 20))
    ) THEN
        RAISE EXCEPTION 'Practice 11-12 edge-case upgrade refused: attempt 13 is missing or changed. Save work and inspect it with your TA.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM advanced_lab.attempts WHERE attempt_id = 14
        AND (student_id, course_id, grade) IN ((1123, 29, 98), (6, 4, 80))
    ) THEN
        RAISE EXCEPTION 'Practice 11-12 edge-case upgrade refused: attempt 14 is missing or changed. Save work and inspect it with your TA.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM advanced_lab.portal_events WHERE event_id = 25
        AND (student_id, occurred_at, event_type) IN (
            (876, timestamptz '2026-01-02 16:25+00', 'view'),
            (42, timestamptz '2026-03-01 01:31:30+00', 'view')
        )
    ) THEN
        RAISE EXCEPTION 'Practice 11-12 edge-case upgrade refused: event 25 is missing or changed. Save work and inspect it with your TA.';
    END IF;

    UPDATE advanced_lab.attempts SET student_id = 1, course_id = 1, grade = 20
    WHERE attempt_id = 13 AND (student_id, course_id, grade) = (1050, 12, 91);
    UPDATE advanced_lab.attempts SET student_id = 6, course_id = 4, grade = 80
    WHERE attempt_id = 14 AND (student_id, course_id, grade) = (1123, 29, 98);
    UPDATE advanced_lab.portal_events
    SET student_id = 42, occurred_at = timestamptz '2026-03-01 01:31:30+00'
    WHERE event_id = 25
      AND (student_id, occurred_at, event_type) = (876, timestamptz '2026-01-02 16:25+00', 'view');

    IF NOT EXISTS (SELECT 1 FROM advanced_lab.attempts
                   WHERE (attempt_id, student_id, course_id, grade) = (13, 1, 1, 20))
       OR NOT EXISTS (SELECT 1 FROM advanced_lab.attempts
                      WHERE (attempt_id, student_id, course_id, grade) = (14, 6, 4, 80))
       OR NOT EXISTS (SELECT 1 FROM advanced_lab.portal_events
                      WHERE (event_id, student_id, occurred_at, event_type) =
                            (25, 42, timestamptz '2026-03-01 01:31:30+00', 'view')) THEN
        RAISE EXCEPTION 'Practice 11-12 edge-case upgrade refused: final validation failed.';
    END IF;
END
$$;
COMMIT;
ANALYZE advanced_lab.attempts;
ANALYZE advanced_lab.portal_events;
