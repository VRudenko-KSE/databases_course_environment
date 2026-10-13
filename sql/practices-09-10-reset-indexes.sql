\set ON_ERROR_STOP on
-- Removes all non-constraint indexes on the lab's main table; keeps rows and constraints.
DO $$
DECLARE candidate record;
BEGIN
    FOR candidate IN
        SELECT i.indexrelid::regclass AS index_name
        FROM pg_index i
        WHERE i.indrelid = 'index_lab.enrolments'::regclass
          AND NOT EXISTS (SELECT 1 FROM pg_constraint c WHERE c.conindid = i.indexrelid)
    LOOP
        EXECUTE format('DROP INDEX %s', candidate.index_name);
    END LOOP;
END
$$;
ANALYZE index_lab.enrolments;
