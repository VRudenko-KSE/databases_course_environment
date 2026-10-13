\set ON_ERROR_STOP on
-- Rebuild only the disposable write experiment. Run before EACH measured INSERT.
BEGIN;
DROP SCHEMA IF EXISTS index_write CASCADE;
CREATE SCHEMA index_write;
-- Copy column/check definitions, then recreate constraint indexes explicitly.
-- This deliberately does not copy any student-created indexes from index_lab.
CREATE TABLE index_write.enrolments
    (LIKE index_lab.enrolments INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE index_write.enrolments
    ADD PRIMARY KEY (enrolment_id),
    ADD UNIQUE (offering_id, student_id),
    ADD FOREIGN KEY (student_id) REFERENCES index_lab.students(student_id),
    ADD FOREIGN KEY (offering_id) REFERENCES index_lab.offerings(offering_id);
INSERT INTO index_write.enrolments
SELECT * FROM index_lab.enrolments ORDER BY enrolment_id;
COMMIT;
VACUUM (ANALYZE) index_write.enrolments;
