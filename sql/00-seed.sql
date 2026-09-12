CREATE SCHEMA practice;

ALTER ROLE student IN DATABASE university SET search_path = practice, public;

CREATE TABLE practice.courses (
    course_id integer PRIMARY KEY,
    title text NOT NULL,
    department text NOT NULL,
    credits integer NOT NULL,
    seats_available integer NOT NULL
);

INSERT INTO practice.courses VALUES
    (101, 'Databases', 'CS', 6, 3),
    (102, 'Programming', 'CS', 6, 0),
    (103, 'Algorithms', 'CS', 5, 8),
    (104, 'Networks', 'CS', 5, 2),
    (105, 'Data Ethics', 'CS', 3, 10),
    (201, 'Statistics', 'MATH', 6, 4),
    (202, 'Linear Algebra', 'MATH', 5, 0),
    (301, 'Microeconomics', 'ECON', 4, 6);
