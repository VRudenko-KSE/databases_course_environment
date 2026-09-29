\set ON_ERROR_STOP on
-- Run immediately after a fresh Compose startup, before changing practice data.
-- This catches a missing or incomplete startup migration.
DO $$
BEGIN
    IF (SELECT count(*) FROM practice.enrolments) <> 18 THEN
        RAISE EXCEPTION 'university enrolment seed is incomplete';
    END IF;
    IF (SELECT count(*) FROM library_lab.borrowers) <> 3
       OR (SELECT count(*) FROM library_lab.books) <> 3
       OR (SELECT count(*) FROM library_lab.copies) <> 4
       OR (SELECT count(*) FROM library_lab.loans) <> 3 THEN
        RAISE EXCEPTION 'Practice 3-4 library migration is incomplete';
    END IF;
    IF (SELECT count(*) FROM library_p5.borrowers) <> 3
       OR (SELECT count(*) FROM library_p5.loans) <> 3
       OR (SELECT count(*) FROM library_p5.book_authors) <> 3 THEN
        RAISE EXCEPTION 'Practice 5 library migration is incomplete';
    END IF;
    IF (SELECT count(*) FROM library_p6.borrowers) <> 3
       OR (SELECT count(*) FROM library_p6.loans) <> 3
       OR (SELECT count(*) FROM library_p6.book_authors) <> 3
       OR (SELECT count(*) FROM library_p6.mixed_credits) <> 3
       OR (SELECT count(*) FROM library_p6.author_lists) <> 2
       OR (SELECT count(*) FROM library_p6.publisher_records) <> 3
       OR (SELECT count(*) FROM library_p6.borrower_addresses) <> 2
       OR (SELECT count(*) FROM library_p6.loan_report) <> 3 THEN
        RAISE EXCEPTION 'Practice 6 library migration is incomplete';
    END IF;
END
$$;

SELECT 'Practice data ready' AS result;
