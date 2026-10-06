\set ON_ERROR_STOP on
BEGIN;

-- Synthetic storage fixture. These IDs do not add facts to the university data.
-- No indexes: all P8 predicates must be evaluated by scanning table records.
CREATE SCHEMA storage_lab;
CREATE TABLE storage_lab.enrolments_narrow (
    record_id integer NOT NULL,
    student_id integer NOT NULL,
    offering_id integer NOT NULL,
    grade numeric NOT NULL,
    registration_note text NOT NULL
) WITH (autovacuum_enabled = false);
CREATE TABLE storage_lab.enrolments_wide
    (LIKE storage_lab.enrolments_narrow INCLUDING ALL)
    WITH (autovacuum_enabled = false);
CREATE TABLE storage_lab.enrolments_grouped
    (LIKE storage_lab.enrolments_narrow INCLUDING ALL)
    WITH (autovacuum_enabled = false);

INSERT INTO storage_lab.enrolments_narrow
SELECT n,
       ((n - 1) % 4000) + 1,
       1001 + ((n - 1) % 4),
       (n * 7) % 101,
       'registered'
FROM generate_series(1, 40000) AS source(n)
ORDER BY n;

INSERT INTO storage_lab.enrolments_wide
SELECT record_id, student_id, offering_id, grade,
       repeat(md5(record_id::text), 8)
FROM storage_lab.enrolments_narrow
ORDER BY record_id;

INSERT INTO storage_lab.enrolments_grouped
SELECT * FROM storage_lab.enrolments_narrow
ORDER BY student_id, record_id;

-- ctid is the current (page number, item position), not a logical row key.
-- These ordinary views expose live locations; they do not store a page map.
CREATE VIEW storage_lab.narrow_locations AS
SELECT record_id, student_id, offering_id, grade,
       ctid AS row_location,
       split_part(ltrim(ctid::text, '('), ',', 1)::integer AS page_no
FROM storage_lab.enrolments_narrow;

CREATE VIEW storage_lab.grouped_locations AS
SELECT record_id, student_id, offering_id, grade,
       ctid AS row_location,
       split_part(ltrim(ctid::text, '('), ',', 1)::integer AS page_no
FROM storage_lab.enrolments_grouped;

ANALYZE storage_lab.enrolments_narrow;
ANALYZE storage_lab.enrolments_wide;
ANALYZE storage_lab.enrolments_grouped;
COMMIT;
