-- Independent teaching fixture: p14_serializable. Install only when absent.
BEGIN;
CREATE SCHEMA p14_serializable;
CREATE TABLE p14_serializable.exams (exam_id integer PRIMARY KEY);
CREATE TABLE p14_serializable.invigilators (exam_id integer REFERENCES p14_serializable.exams, staff_code text, on_duty boolean NOT NULL, PRIMARY KEY(exam_id,staff_code));
INSERT INTO p14_serializable.exams VALUES (1403);
INSERT INTO p14_serializable.invigilators VALUES (1403,'I-A',true),(1403,'I-B',true);
COMMIT;
