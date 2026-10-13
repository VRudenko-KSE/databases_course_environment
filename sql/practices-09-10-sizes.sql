SELECT schemaname, tablename, indexname, indexdef,
       pg_relation_size(format('%I.%I', schemaname, indexname)::regclass) AS index_bytes,
       pg_size_pretty(pg_relation_size(format('%I.%I', schemaname, indexname)::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname IN ('index_lab', 'index_write') AND tablename = 'enrolments'
ORDER BY schemaname, indexname;

SELECT schemaname, relname,
       pg_relation_size(relid) AS table_bytes,
       pg_indexes_size(relid) AS index_bytes,
       pg_total_relation_size(relid) AS total_bytes
FROM pg_stat_user_tables
WHERE schemaname IN ('index_lab', 'index_write') AND relname = 'enrolments'
ORDER BY schemaname;
