-- Independent teaching fixture: p14_visibility. Install only when absent.
BEGIN;
CREATE SCHEMA p14_visibility;
CREATE TABLE p14_visibility.rooms (room_id integer PRIMARY KEY, capacity integer NOT NULL CHECK (capacity>0));
INSERT INTO p14_visibility.rooms VALUES (1401,30);
COMMIT;
