\set ON_ERROR_STOP on
-- Remove experimental indexes throughout advanced_lab; preserve rows and constraints.
DO $$
DECLARE candidate record;
BEGIN
    FOR candidate IN
        SELECT i.indexrelid::regclass AS index_name
        FROM pg_index AS i
        JOIN pg_class AS t ON t.oid = i.indrelid
        JOIN pg_namespace AS n ON n.oid = t.relnamespace
        WHERE n.nspname = 'advanced_lab'
          AND NOT EXISTS (
              SELECT 1 FROM pg_constraint AS c WHERE c.conindid = i.indexrelid
          )
    LOOP
        EXECUTE format('DROP INDEX %s', candidate.index_name);
    END LOOP;
END
$$;
ANALYZE advanced_lab.programmes;
ANALYZE advanced_lab.students;
ANALYZE advanced_lab.courses;
ANALYZE advanced_lab.requirements;
ANALYZE advanced_lab.attempts;
ANALYZE advanced_lab.rooms;
ANALYZE advanced_lab.bookings;
ANALYZE advanced_lab.portal_events;
