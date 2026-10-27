-- Ordinary SQL: run this whole file, with A and B idle and outside transactions.
-- Restores only p14_serializable; save observations first. On error: ROLLBACK; inspect the diagnostic.
BEGIN;
SET LOCAL lock_timeout='1500ms';
DROP TABLE IF EXISTS p14_serializable.invigilators, p14_serializable.exams RESTRICT;
DROP SCHEMA p14_serializable RESTRICT;
CREATE SCHEMA p14_serializable;
CREATE TABLE p14_serializable.exams (exam_id integer PRIMARY KEY);
CREATE TABLE p14_serializable.invigilators (exam_id integer REFERENCES p14_serializable.exams, staff_code text, on_duty boolean NOT NULL, PRIMARY KEY(exam_id,staff_code));
INSERT INTO p14_serializable.exams VALUES (1403);
INSERT INTO p14_serializable.invigilators VALUES (1403,'I-A',true),(1403,'I-B',true);
COMMIT;
