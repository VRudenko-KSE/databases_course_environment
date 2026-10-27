-- Independent teaching fixture: p13_locking. Install only when absent.
BEGIN;
CREATE SCHEMA p13_locking;
CREATE TABLE p13_locking.workshops (workshop_id integer PRIMARY KEY, capacity integer NOT NULL CHECK (capacity>0));
CREATE TABLE p13_locking.registrations (workshop_id integer REFERENCES p13_locking.workshops, learner_code text, PRIMARY KEY(workshop_id,learner_code));
INSERT INTO p13_locking.workshops VALUES (1304,1);
COMMIT;
