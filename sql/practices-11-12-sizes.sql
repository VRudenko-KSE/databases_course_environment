SELECT schemaname, tablename, indexname, indexdef,
       pg_relation_size(format('%I.%I', schemaname, indexname)::regclass) AS index_bytes,
       pg_size_pretty(pg_relation_size(format('%I.%I', schemaname, indexname)::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'advanced_lab'
ORDER BY tablename, indexname;

SELECT schemaname, relname,
       pg_relation_size(relid) AS table_bytes,
       pg_indexes_size(relid) AS index_bytes,
       pg_total_relation_size(relid) AS total_bytes
FROM pg_stat_user_tables
WHERE schemaname = 'advanced_lab'
ORDER BY relname;
