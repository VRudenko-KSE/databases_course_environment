\set ON_ERROR_STOP on
-- Practice 3-4 library baseline. Practice 3 may later reset library_lab to empty
-- for the modelling exercise; fresh volume creation restores this baseline.
BEGIN;
CREATE SCHEMA library_lab;
\i /course/sql/library/01-schema.sql
\i /course/sql/library/02-seed.sql
COMMIT;
