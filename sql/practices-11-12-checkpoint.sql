\set ON_ERROR_STOP on
-- Explicit recovery: discard P11/P12 data edits and index experiments.
-- Refuse if another object depends on a fixture table, or unexpected objects
-- remain in the schema. The transaction preserves all tables on such refusal.
-- Earlier practice schemas and host work files are preserved.
-- If refused inside an interactive psql session, run ROLLBACK; before continuing.
BEGIN;
DROP TABLE IF EXISTS
    advanced_lab.portal_events, advanced_lab.bookings, advanced_lab.rooms,
    advanced_lab.attempts, advanced_lab.requirements, advanced_lab.students,
    advanced_lab.courses, advanced_lab.programmes
RESTRICT;
DROP SCHEMA IF EXISTS advanced_lab RESTRICT;
COMMIT;
\ir migrations/70-practices-11-12.sql
\ir migrations/71-practices-11-12-edge-cases.sql
\ir practices-11-12-ready.sql
