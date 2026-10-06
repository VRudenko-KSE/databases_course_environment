\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA reporting_lab;
CREATE TABLE reporting_lab.teachers (
    teacher_id integer PRIMARY KEY,
    full_name text NOT NULL
);
CREATE TABLE reporting_lab.offering_teachers (
    offering_id integer NOT NULL,
    teacher_id integer REFERENCES reporting_lab.teachers(teacher_id),
    PRIMARY KEY (offering_id, teacher_id)
);
INSERT INTO reporting_lab.teachers VALUES (10, 'Mira'), (11, 'Oleh');
INSERT INTO reporting_lab.offering_teachers VALUES
    (1001,10), (1001,11), (1002,10), (1003,11), (1004,10),
    (1005,11), (1006,10), (1007,11), (1008,10);

-- Lab identifiers deliberately have no cross-schema FKs, so reset-practice.sql stays independent.
-- Fictional reporting exercise results, NOT a replacement for practice.enrolments.
-- Ties at the top-two boundary, ungraded rows, equal dates, and a missing date are deliberate.
CREATE TABLE reporting_lab.results (
    student_id integer NOT NULL,
    offering_id integer NOT NULL,
    enrolled_on date NOT NULL,
    grade numeric(5,2) CHECK (grade BETWEEN 0 AND 100),
    PRIMARY KEY (student_id, offering_id)
);
INSERT INTO reporting_lab.results VALUES
    (1,1001,'2026-02-02',100), (2,1001,'2026-02-02',90),
    (3,1001,'2026-02-03',90), (4,1001,'2026-02-03',80),
    (5,1001,'2026-02-05',60), (6,1001,'2026-02-06',0),
    (7,1001,'2026-02-06',NULL),
    (1,1002,'2026-02-02',95), (2,1002,'2026-02-03',95),
    (3,1002,'2026-02-05',85), (4,1002,'2026-02-05',70),
    (5,1002,'2026-02-06',70), (6,1002,'2026-02-06',NULL),
    (7,1002,'2026-02-06',65);
COMMIT;
