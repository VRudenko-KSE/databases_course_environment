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
    IF (SELECT count(*) FROM storage_lab.enrolments_narrow) <> 40000
       OR (SELECT count(*) FROM storage_lab.enrolments_wide) <> 40000
       OR (SELECT count(*) FROM storage_lab.enrolments_grouped) <> 40000
       OR to_regclass('storage_lab.narrow_locations') IS NULL
       OR to_regclass('storage_lab.grouped_locations') IS NULL THEN
        RAISE EXCEPTION 'Storage investigation migration is incomplete';
    END IF;
    IF (SELECT count(*) FROM reporting_lab.teachers) <> 2
       OR (SELECT count(*) FROM reporting_lab.offering_teachers) <> 9
       OR (SELECT count(*) FROM reporting_lab.results) <> 14
       OR (SELECT count(*) FROM reporting_lab.results WHERE grade IS NOT NULL) <> 12 THEN
        RAISE EXCEPTION 'Practice 7-8 reporting migration is incomplete';
    END IF;
    IF (SELECT count(*) FROM activity_lab.students) <> 7
       OR (SELECT count(*) FROM activity_lab.workshops) <> 4
       OR (SELECT count(*) FROM activity_lab.registrations) <> 10
       OR (SELECT count(*) FROM activity_lab.registration_events) <> 18 THEN
        RAISE EXCEPTION 'Practice 7 activity migration is incomplete';
    END IF;
END
$$;

SELECT 'Practice data ready' AS result;
