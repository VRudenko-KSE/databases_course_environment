CREATE SCHEMA practice;

ALTER ROLE student IN DATABASE university SET search_path = practice, public;

-- One row per course. seats_available is a Week 1 introductory snapshot;
-- it is not calculated from the later offering and enrolment fixtures.
CREATE TABLE practice.courses (
    course_id integer PRIMARY KEY,
    title text NOT NULL,
    department text NOT NULL,
    credits integer NOT NULL,
    seats_available integer NOT NULL
);

INSERT INTO practice.courses
    (course_id, title, department, credits, seats_available)
VALUES
    (101, 'Databases', 'CS', 6, 3),
    (102, 'Programming', 'CS', 6, 0),
    (103, 'Algorithms', 'CS', 5, 8),
    (104, 'Networks', 'CS', 5, 2),
    (105, 'Data Ethics', 'CS', 3, 10),
    (201, 'Statistics', 'MATH', 6, 4),
    (202, 'Linear Algebra', 'MATH', 5, 0),
    (301, 'Microeconomics', 'ECON', 4, 6);

-- One row per student; hometown is intentionally optional.
CREATE TABLE practice.students (
    student_id integer PRIMARY KEY,
    full_name text NOT NULL,
    email text NOT NULL UNIQUE,
    cohort_year integer NOT NULL,
    hometown text
);

-- One row per scheduled course section. A course can recur by term or section.
CREATE TABLE practice.course_offerings (
    offering_id integer PRIMARY KEY,
    course_id integer NOT NULL REFERENCES practice.courses (course_id),
    term text NOT NULL,
    section text NOT NULL,
    UNIQUE (course_id, term, section)
);

-- One row per student in an offering. A NULL grade means no grade is recorded.
CREATE TABLE practice.enrolments (
    student_id integer NOT NULL REFERENCES practice.students (student_id),
    offering_id integer NOT NULL REFERENCES practice.course_offerings (offering_id),
    enrolled_on date NOT NULL,
    grade numeric(5, 2) CHECK (grade BETWEEN 0 AND 100),
    PRIMARY KEY (student_id, offering_id)
);

INSERT INTO practice.students
    (student_id, full_name, email, cohort_year, hometown)
VALUES
    (1, 'Anna Kovalenko', 'anna.kovalenko@example.edu', 2025, 'Kyiv'),
    (2, 'Bohdan Melnyk', 'bohdan.melnyk@example.edu', 2025, 'Lviv'),
    (3, 'Carla Ortiz', 'carla.ortiz@example.edu', 2025, 'Kyiv'),
    (4, 'Danylo Shevchenko', 'danylo.shevchenko@example.edu', 2024, 'Odesa'),
    (5, 'Eva Novak', 'eva.novak@example.edu', 2024, NULL),
    (6, 'Farid Khan', 'farid.khan@example.edu', 2026, 'Lviv'),
    (7, 'Grace Lee', 'grace.lee@example.edu', 2026, NULL);

INSERT INTO practice.course_offerings
    (offering_id, course_id, term, section)
VALUES
    (1001, 101, '2025-autumn', 'A'),
    (1002, 101, '2026-spring', 'A'),
    (1003, 101, '2026-spring', 'B'),
    (1004, 102, '2025-autumn', 'A'),
    (1005, 103, '2025-autumn', 'A'),
    (1006, 201, '2025-autumn', 'A'),
    (1007, 202, '2026-spring', 'A'),
    (1008, 301, '2026-spring', 'A');

-- Edge cases are deliberate: student 7 has no enrolments; offering 1007 is
-- empty; 1008 has only NULL grades; 1001 mixes NULL and numeric grades.
-- Repeated grades, tied averages, and student 1's course retake support later
-- grouping, set, and subquery exercises without enlarging the default seed.
INSERT INTO practice.enrolments
    (student_id, offering_id, enrolled_on, grade)
VALUES
    (1, 1001, DATE '2025-09-01', 80),
    (2, 1001, DATE '2025-09-01', 90),
    (3, 1001, DATE '2025-09-02', NULL),
    (4, 1001, DATE '2025-09-03', 0),
    (1, 1002, DATE '2026-02-02', 100),
    (5, 1002, DATE '2026-02-02', 90),
    (6, 1002, DATE '2026-02-03', NULL),
    (2, 1003, DATE '2026-02-02', 80),
    (5, 1003, DATE '2026-02-03', 80),
    (1, 1004, DATE '2025-09-01', 75),
    (4, 1004, DATE '2025-09-04', 75),
    (3, 1005, DATE '2025-09-01', 60),
    (4, 1005, DATE '2025-09-01', 90),
    (5, 1005, DATE '2025-09-02', NULL),
    (2, 1006, DATE '2025-09-01', 100),
    (6, 1006, DATE '2025-09-05', 0),
    (5, 1008, DATE '2026-02-02', NULL),
    (6, 1008, DATE '2026-02-02', NULL);

-- Extend this fixture with stable offering IDs and matching enrolment rows.
-- Departments and instructors can become separate entities when a later topic
-- needs them; they are intentionally not part of this compact teaching model.
