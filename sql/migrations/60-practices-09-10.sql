\set ON_ERROR_STOP on
BEGIN;
-- Fictional, deterministic index workshop. Earlier schemas are independent.
CREATE SCHEMA index_lab;
CREATE TABLE index_lab.students (
    student_id integer PRIMARY KEY,
    full_name text NOT NULL
);
CREATE TABLE index_lab.courses (
    course_id integer PRIMARY KEY,
    title text NOT NULL
);
CREATE TABLE index_lab.offerings (
    offering_id integer PRIMARY KEY,
    course_id integer NOT NULL REFERENCES index_lab.courses(course_id),
    semester text NOT NULL
);
CREATE TABLE index_lab.enrolments (
    enrolment_id integer PRIMARY KEY,
    student_id integer NOT NULL REFERENCES index_lab.students(student_id),
    offering_id integer NOT NULL REFERENCES index_lab.offerings(offering_id),
    registered_at timestamptz NOT NULL,
    status text NOT NULL CHECK (status IN ('completed', 'active', 'cancelled')),
    grade integer CHECK (grade BETWEEN 0 AND 100),
    registration_note text NOT NULL,
    UNIQUE (offering_id, student_id),
    CHECK (status = 'completed' OR grade IS NULL)
);

INSERT INTO index_lab.students
SELECT n, 'Student ' || lpad(n::text, 6, '0') FROM generate_series(1, 100000) g(n);
INSERT INTO index_lab.courses
SELECT n, 'Course ' || lpad(n::text, 3, '0') FROM generate_series(1, 500) g(n);
INSERT INTO index_lab.offerings
SELECT n, 1 + (n - 1) % 500, '2026 Spring' FROM generate_series(1, 10000) g(n);

-- Each student has 20 distinct offerings; offering 10000 is deliberately empty.
-- Coprime strides spread dates and grades rather than sorting the heap by a report key.
WITH source AS (
    SELECT n, 1 + (n - 1) % 100000 AS student_id, (n - 1) / 100000 AS round_no,
           (n::bigint * 7919 % 179)::integer AS day_slot,
           CASE WHEN n * 43 % 100 = 0 THEN 'cancelled'
                WHEN n * 43 % 100 < 10 THEN 'active'
                ELSE 'completed' END AS status
    FROM generate_series(1, 2000000) g(n)
)
INSERT INTO index_lab.enrolments
SELECT n, student_id, 1 + (student_id - 1 + round_no * 37) % 9999,
       CASE n
           WHEN 1 THEN TIMESTAMPTZ '2026-02-28 23:59:59+00'
           WHEN 2 THEN TIMESTAMPTZ '2026-03-01 00:00:00+00'
           WHEN 3 THEN TIMESTAMPTZ '2026-03-31 23:59:59+00'
           WHEN 4 THEN TIMESTAMPTZ '2026-04-01 00:00:00+00'
           ELSE TIMESTAMPTZ '2026-01-01 00:00:00+00'
                + (day_slot + CASE WHEN day_slot >= 62 THEN 1 ELSE 0 END) * INTERVAL '1 day'
                + (n::bigint * 3571 % 86400) * INTERVAL '1 second'
       END,
       status, CASE WHEN status = 'completed' THEN n * 17 % 101 END,
       'Fictional registration ' || n || '; imported from campus portal; reference '
           || md5('registration-' || n)
FROM source ORDER BY n;

-- A tie across the third-place boundary: ROW_NUMBER <= 3 and RANK <= 3 differ.
WITH ranked AS (
    SELECT enrolment_id, row_number() OVER (ORDER BY student_id) AS position
    FROM index_lab.enrolments WHERE offering_id = 101 AND status = 'completed'
)
UPDATE index_lab.enrolments e
SET grade = CASE WHEN r.position = 1 THEN 100 WHEN r.position <= 4 THEN 95 ELSE least(e.grade, 90) END
FROM ranked r WHERE e.enrolment_id = r.enrolment_id;

-- The latest-20 task must use its ID tie-breaker: 25 rows share the latest timestamp.
UPDATE index_lab.enrolments
SET registered_at = TIMESTAMPTZ '2026-06-29 23:59:59+00'
WHERE enrolment_id IN (
    SELECT enrolment_id FROM index_lab.enrolments WHERE offering_id = 101
    ORDER BY enrolment_id LIMIT 25
);

-- Supplied new associations for the repeatable scratch INSERT, never the canonical table.
CREATE TABLE index_lab.ingest_batch (LIKE index_lab.enrolments INCLUDING ALL);
INSERT INTO index_lab.ingest_batch
SELECT 2000000 + n, n, 1 + (n - 1 + 20 * 37) % 9999,
       TIMESTAMPTZ '2026-06-30 00:00:00+00' + n * INTERVAL '1 second',
       'active', NULL, 'Supplied new registration ' || n
FROM generate_series(1, 1000) g(n);
COMMIT;

VACUUM (ANALYZE) index_lab.enrolments;
ANALYZE index_lab.students;
ANALYZE index_lab.courses;
ANALYZE index_lab.offerings;
ANALYZE index_lab.ingest_batch;
