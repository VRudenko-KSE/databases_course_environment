-- Independent teaching fixture: p13_atomicity. Install only when absent.
BEGIN;
CREATE SCHEMA p13_atomicity;
CREATE TABLE p13_atomicity.copies (copy_id integer PRIMARY KEY, state text NOT NULL CHECK (state IN ('available','loaned')));
CREATE TABLE p13_atomicity.loans (loan_id integer PRIMARY KEY, copy_id integer NOT NULL UNIQUE REFERENCES p13_atomicity.copies, borrower_code text NOT NULL);
INSERT INTO p13_atomicity.copies VALUES (1301,'available');
COMMIT;
