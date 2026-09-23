\set ON_ERROR_STOP on
-- Practice 3 recovery before the INSERT exercise: tables but NO rows.
-- Replaces only library_lab. Save your work first.
BEGIN;
DROP SCHEMA IF EXISTS library_lab CASCADE;
CREATE SCHEMA library_lab;
\ir library/01-schema.sql
COMMIT;
SELECT 'Four empty tables; write and run your inserts next' AS checkpoint;
