-- Ordinary SQL: run this whole file, with A and B idle and outside transactions.
-- Restores only p13_locking; save observations first. On error: ROLLBACK; inspect the diagnostic.
BEGIN;
SET LOCAL lock_timeout='1500ms';
DROP TABLE IF EXISTS p13_locking.registrations, p13_locking.workshops RESTRICT;
DROP SCHEMA p13_locking RESTRICT;
CREATE SCHEMA p13_locking;
CREATE TABLE p13_locking.workshops (workshop_id integer PRIMARY KEY, capacity integer NOT NULL CHECK (capacity>0));
CREATE TABLE p13_locking.registrations (workshop_id integer REFERENCES p13_locking.workshops, learner_code text, PRIMARY KEY(workshop_id,learner_code));
INSERT INTO p13_locking.workshops VALUES (1304,1);
COMMIT;
