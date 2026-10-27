-- Ordinary SQL: run this whole file, with A and B idle and outside transactions.
-- Restores only p13_atomicity; save observations first. On error: ROLLBACK; inspect the diagnostic.
BEGIN;
SET LOCAL lock_timeout='1500ms';
DROP TABLE IF EXISTS p13_atomicity.loans, p13_atomicity.copies RESTRICT;
DROP SCHEMA p13_atomicity RESTRICT;
CREATE SCHEMA p13_atomicity;
CREATE TABLE p13_atomicity.copies (copy_id integer PRIMARY KEY, state text NOT NULL CHECK (state IN ('available','loaned')));
CREATE TABLE p13_atomicity.loans (loan_id integer PRIMARY KEY, copy_id integer NOT NULL UNIQUE REFERENCES p13_atomicity.copies, borrower_code text NOT NULL);
INSERT INTO p13_atomicity.copies VALUES (1301,'available');
COMMIT;
