-- Independent teaching fixture: p13_cte. Install only when absent.
BEGIN;
CREATE SCHEMA p13_cte;
CREATE TABLE p13_cte.copies (copy_id integer PRIMARY KEY, state text NOT NULL CHECK (state IN ('available','loaned')));
CREATE TABLE p13_cte.loans (loan_id integer PRIMARY KEY, copy_id integer NOT NULL UNIQUE REFERENCES p13_cte.copies, borrower_code text NOT NULL);
INSERT INTO p13_cte.copies VALUES (1301,'available');
COMMIT;
