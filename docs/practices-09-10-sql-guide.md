# Index and Plan SQL Guide

Use this syntax reference alongside the [tasks](practices-09-10.md). Examples use unrelated illustrative tables;
adapt them to your own query. PostgreSQL chooses among available paths; do not force a scan type.

## Create and Compare Indexes

```sql
CREATE INDEX readings_device_idx ON sample.readings (device_id);
CREATE INDEX readings_recent_idx ON sample.readings (device_id, recorded_at DESC);
ANALYZE sample.readings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT recorded_at, temperature
FROM sample.readings
WHERE device_id = 7
ORDER BY recorded_at DESC;

DROP INDEX sample.readings_recent_idx;
```

Use the task's scoped reset to remove experimental indexes together. Keep primary-key and unique indexes intact.
Foreign keys do not automatically create an index on their referencing columns.
Use a direct timestamp range with an inclusive lower and exclusive upper boundary. Grouping by a date expression
does not require wrapping the timestamp in that expression in the WHERE clause.

With a composite B-tree, leading equality predicates and then a range often narrow the accessed portion.
Column order also determines which ordering the index may supply. Do not claim that an index is unusable whenever
a leading column is absent: PostgreSQL 18 can use skip scans in suitable cases. Test the actual query and distribution.
See [Multicolumn Indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html) and
[Indexes and ORDER BY](https://www.postgresql.org/docs/18/indexes-ordering.html).
An index does not promise displayed row order; write the query's ORDER BY explicitly.

## Read the Plan From Its Work

<!-- rumdl-disable MD013 -->

| Field or Node | Read It As | Avoid This Mistake |
|---|---|---|
| Seq Scan / Index Scan / Bitmap nodes | Observed route to candidate rows | Treating every scan as a failure |
| Index Cond | Condition applied through the index | Assuming all WHERE conditions narrow the index range equally |
| Filter / Rows Removed by Filter | Remaining qualification and rejected rows at that node | Treating returned rows as all examined rows |
| Estimated rows / actual rows | Predicted versus observed output per execution of the node | Reading planner cost as milliseconds |
| loops | Number of node executions; actual rows/time are per-loop averages when repeated | Comparing a repeated inner scan as though it ran once |
| shared hit / read | Buffer requests served from shared buffers / requiring a read into them | Calling a shared read a guaranteed physical disk read |
| Sort / Aggregate / WindowAgg | Further ordering or calculation after input access | Assuming an index eliminates every downstream operation |
| Execution Time | Instrumented execution under recorded conditions | Inferring a universal speedup from one run |

<!-- rumdl-enable MD013 -->

Parent buffer/time observations can include child work. Do not sum all nodes as independent totals.
Name the node when reporting a metric. Warm-ups improve consistency but do not establish a cold cache,
and the operating system may cache a read outside PostgreSQL's shared buffers.
For details and worked examples see [Using EXPLAIN](https://www.postgresql.org/docs/18/using-explain.html).

## Optional Partial and Covering Indexes

```sql
CREATE INDEX readings_errors_idx ON sample.readings (recorded_at)
WHERE status = 'error';

CREATE INDEX readings_cover_idx ON sample.readings (device_id)
INCLUDE (recorded_at, temperature);
```

A partial index stores only rows satisfying its predicate. A query must imply that predicate for the index
to be a valid access choice; compare a matching and a non-matching query.
See [Partial Indexes](https://www.postgresql.org/docs/18/indexes-partial.html).

INCLUDE stores payload columns without making them search/order keys. An index-only scan can supply needed
values from the index, but heap visibility checks can still require heap fetches. The freshly prepared fixture is
vacuumed; later writes can change visibility. Inspect the observed Heap Fetches rather than promising zero.
See [Index-Only Scans](https://www.postgresql.org/docs/18/indexes-index-only-scans.html).

## Report Correctness Still Comes First

- For a left join, count a non-NULL child key to avoid counting an empty parent's placeholder row.
- COUNT(grade) ignores NULL; a grade of zero is included. AVG also ignores NULL.
- Select the date interval before daily aggregation; a generated calendar supplies absent dates afterward.
- ROW_NUMBER with a unique tie-breaker selects exactly N rows; rank peers depend on all window ordering columns.
- Calculate a window in a CTE before filtering its result. Aggregate daily counts before a running window.
- A final ORDER BY controls display; a window ORDER BY controls calculation.

The [P7/P8 SQL guide](practices-07-08-sql-guide.md) contains the corresponding report syntax.
