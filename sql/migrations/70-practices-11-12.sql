\set ON_ERROR_STOP on
-- Apply once. Use practices-11-12-checkpoint.sql for an explicit scoped rebuild.
-- Fictional deterministic fixture; UTC prevents local-time calendar surprises.
SET TIME ZONE 'UTC';
BEGIN;
CREATE SCHEMA advanced_lab;

CREATE TABLE advanced_lab.programmes (
    programme_id integer PRIMARY KEY,
    programme_name text NOT NULL
);
CREATE TABLE advanced_lab.students (
    student_id integer PRIMARY KEY,
    full_name text NOT NULL,
    programme_id integer NOT NULL REFERENCES advanced_lab.programmes
);
CREATE TABLE advanced_lab.courses (
    course_id integer PRIMARY KEY,
    title text NOT NULL
);
CREATE TABLE advanced_lab.requirements (
    programme_id integer NOT NULL REFERENCES advanced_lab.programmes,
    course_id integer NOT NULL REFERENCES advanced_lab.courses,
    PRIMARY KEY (programme_id, course_id)
);
CREATE TABLE advanced_lab.attempts (
    attempt_id integer PRIMARY KEY,
    student_id integer NOT NULL REFERENCES advanced_lab.students,
    course_id integer NOT NULL REFERENCES advanced_lab.courses,
    grade integer CHECK (grade BETWEEN 0 AND 100)
);
CREATE TABLE advanced_lab.rooms (
    room_id integer PRIMARY KEY,
    room_name text NOT NULL,
    capacity integer NOT NULL CHECK (capacity > 0)
);
CREATE TABLE advanced_lab.bookings (
    booking_id integer PRIMARY KEY,
    room_id integer NOT NULL REFERENCES advanced_lab.rooms,
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    CHECK (starts_at < ends_at)
);
CREATE TABLE advanced_lab.portal_events (
    event_id integer PRIMARY KEY,
    student_id integer NOT NULL REFERENCES advanced_lab.students,
    occurred_at timestamptz NOT NULL,
    event_type text NOT NULL
);

INSERT INTO advanced_lab.programmes
SELECT g, CASE WHEN g = 10 THEN 'Open programme' ELSE 'Programme ' || g END
FROM generate_series(1, 10) AS g;
INSERT INTO advanced_lab.courses
SELECT g, 'Course ' || g FROM generate_series(1, 30) AS g;
INSERT INTO advanced_lab.requirements
SELECT p, (p - 1) * 3 + c
FROM generate_series(1, 9) AS p CROSS JOIN generate_series(1, 3) AS c;
INSERT INTO advanced_lab.students
SELECT g,
       CASE g WHEN 1 THEN 'Olena Bondar' WHEN 2 THEN 'OLENA BONDAR'
              WHEN 3 THEN 'olena bondar' ELSE 'Student ' || lpad(g::text, 5, '0') END,
       CASE WHEN g <= 9 THEN 1 ELSE (g - 1) % 10 + 1 END
FROM generate_series(1, 10000) AS g;
-- Programme 1 requires courses 1, 2, 3. Reserved students 1–100 keep small cases readable.
-- Student 2 repeats a pass but lacks a passing course 2; student 4 has no attempts.
INSERT INTO advanced_lab.attempts VALUES
    (1, 1, 1, 70), (2, 1, 2, 80), (3, 1, 3, 60),
    (4, 2, 1, 80), (5, 2, 1, 90), (6, 2, 2, NULL), (7, 2, 3, 80),
    (8, 3, 1, NULL), (9, 3, 2, 0),
    (10, 5, 1, 60), (11, 5, 2, 60), (12, 5, 3, 60);
INSERT INTO advanced_lab.attempts
SELECT g, 101 + (g * 73) % 9900, 1 + (g * 17) % 30,
       CASE WHEN g % 11 = 0 THEN NULL ELSE (g * 7) % 101 END
FROM generate_series(13, 100000) AS g;

INSERT INTO advanced_lab.rooms
SELECT g, 'Room ' || lpad(g::text, 3, '0'), CASE WHEN g = 3 THEN 20 ELSE 40 END
FROM generate_series(1, 200) AS g;
INSERT INTO advanced_lab.bookings VALUES
    (1, 1, '2026-10-20 09:00+00', '2026-10-20 10:00+00'),
    (2, 1, '2026-10-20 09:30+00', '2026-10-20 10:30+00'),
    (3, 1, '2026-10-20 10:00+00', '2026-10-20 11:00+00'),
    (4, 1, '2026-10-20 11:00+00', '2026-10-20 12:00+00'),
    (5, 1, '2026-10-20 08:00+00', '2026-10-20 09:00+00'),
    (6, 1, '2026-10-20 12:00+00', '2026-10-20 13:00+00'),
    (7, 2, '2026-10-20 09:00+00', '2026-10-20 10:00+00'),
    (8, 2, '2026-10-20 11:00+00', '2026-10-20 12:00+00');
-- Historical background does not interfere with the small October interval cases.
-- Groups of seven equal starts_at values deliberately cross the deep page boundary.
INSERT INTO advanced_lab.bookings
SELECT g, 4 + (g * 37) % 196,
       timestamptz '2025-01-01 00:00+00' + ((g - 9) / 7) * interval '1 minute',
       timestamptz '2025-01-01 00:00+00' + ((g - 9) / 7) * interval '1 minute'
           + (30 + g % 90) * interval '1 minute'
FROM generate_series(9, 200000) AS g;

-- Student 42: report boundaries, exactly 30 minutes, 31 minutes, equal timestamps,
-- missing dates, several streaks; student 43 deliberately has no events.
INSERT INTO advanced_lab.portal_events VALUES
    (1, 42, '2026-02-28 23:59+00', 'view'),
    (2, 42, '2026-03-01 00:00+00', 'login'),
    (3, 42, '2026-03-01 00:30+00', 'view'),
    (4, 42, '2026-03-01 01:01+00', 'view'),
    (5, 42, '2026-03-01 01:01+00', 'submit'),
    (6, 42, '2026-03-02 12:00+00', 'view'),
    (7, 42, '2026-03-03 12:00+00', 'view'),
    (8, 42, '2026-03-05 12:00+00', 'view'),
    (9, 42, '2026-03-06 12:00+00', 'view'),
    (10, 42, '2026-03-07 12:00+00', 'view'),
    (11, 42, '2026-03-08 00:00+00', 'view'),
    (12, 42, '2026-03-10 12:00+00', 'view'),
    (13, 42, '2026-03-11 12:00+00', 'view'),
    (14, 42, '2026-03-12 12:00+00', 'view'),
    (15, 42, '2026-04-01 00:00+00', 'login'),
    (16, 42, '2026-02-01 00:00+00', 'login'),
    (17, 42, '2026-03-31 23:59+00', 'submit'),
    (18, 44, '2026-03-01 10:00+00', 'login'),
    (19, 44, '2026-03-01 10:10+00', 'view'),
    (20, 44, '2026-03-02 10:00+00', 'view'),
    (21, 44, '2026-03-03 10:00+00', 'view'),
    (22, 44, '2026-03-05 10:00+00', 'view'),
    (23, 44, '2026-03-06 10:00+00', 'view'),
    (24, 44, '2026-03-07 10:00+00', 'view');
INSERT INTO advanced_lab.portal_events
SELECT g, 101 + (g * 31) % 9900,
       timestamptz '2026-01-01 00:00+00' + ((g * 97) % 129600) * interval '1 minute',
       CASE g % 3 WHEN 0 THEN 'login' WHEN 1 THEN 'view' ELSE 'submit' END
FROM generate_series(25, 240000) AS g;
COMMIT;

VACUUM (ANALYZE) advanced_lab.programmes;
VACUUM (ANALYZE) advanced_lab.students;
VACUUM (ANALYZE) advanced_lab.courses;
VACUUM (ANALYZE) advanced_lab.requirements;
VACUUM (ANALYZE) advanced_lab.attempts;
VACUUM (ANALYZE) advanced_lab.rooms;
VACUUM (ANALYZE) advanced_lab.bookings;
VACUUM (ANALYZE) advanced_lab.portal_events;
