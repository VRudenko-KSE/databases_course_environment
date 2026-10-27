-- Ordinary SQL: run this whole file, with A and B idle and outside transactions.
-- Restores only p13_cte; save observations first. On error: ROLLBACK; inspect the diagnostic.
BEGIN;
SET LOCAL lock_timeout='1500ms';
DROP TABLE IF EXISTS p13_cte.loans, p13_cte.copies RESTRICT;
DROP SCHEMA p13_cte RESTRICT;
CREATE SCHEMA p13_cte;
CREATE TABLE p13_cte.copies (copy_id integer PRIMARY KEY, state text NOT NULL CHECK (state IN ('available','loaned')));
CREATE TABLE p13_cte.loans (loan_id integer PRIMARY KEY, copy_id integer NOT NULL UNIQUE REFERENCES p13_cte.copies, borrower_code text NOT NULL);
INSERT INTO p13_cte.copies VALUES (1301,'available');
COMMIT;
