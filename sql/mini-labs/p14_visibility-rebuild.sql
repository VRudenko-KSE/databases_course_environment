-- Ordinary SQL: run this whole file, with A and B idle and outside transactions.
-- Restores only p14_visibility; save observations first. On error: ROLLBACK; inspect the diagnostic.
BEGIN;
SET LOCAL lock_timeout='1500ms';
DROP TABLE IF EXISTS p14_visibility.rooms RESTRICT;
DROP SCHEMA p14_visibility RESTRICT;
CREATE SCHEMA p14_visibility;
CREATE TABLE p14_visibility.rooms (room_id integer PRIMARY KEY, capacity integer NOT NULL CHECK (capacity>0));
INSERT INTO p14_visibility.rooms VALUES (1401,30);
COMMIT;
