\set ON_ERROR_STOP on
-- Replace library_lab with the known-good Practice 3 endpoint.
-- Save your work first. Other schemas and host files are preserved.
BEGIN;
DROP SCHEMA IF EXISTS library_lab CASCADE;
CREATE SCHEMA library_lab;
\ir library/01-schema.sql
\ir library/02-seed.sql
COMMIT;
SELECT 'borrowers' AS table_name, count(*) AS rows FROM library_lab.borrowers
UNION ALL SELECT 'books', count(*) FROM library_lab.books
UNION ALL SELECT 'copies', count(*) FROM library_lab.copies
UNION ALL SELECT 'loans', count(*) FROM library_lab.loans
ORDER BY table_name;
