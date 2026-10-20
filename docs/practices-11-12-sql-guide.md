# SQL Guide: Requirements, Intervals and Ordered Events

Use this guide alongside the [Practice 11–12 tasks](practices-11-12.md).
The small SELECT examples have their own data and can be run independently. Section 10's index definitions
are illustrative DDL for a named example table that is not installed. Adapt each idea to the task's exact
columns, boundaries and output contract. These are syntax demonstrations, not completed exercise queries.
Use PostgreSQL 18 and run `SET TIME ZONE 'UTC';` in every connection.

## 1. EXISTS, NOT EXISTS and “Every”

An existence test asks whether qualifying rows exist. It returns a non-NULL Boolean and does not multiply
the outer row when several inner rows match. A correlated subquery refers to a value from the outer row.

```sql
WITH customers(customer_id) AS (VALUES (1), (2), (3)),
invoices(customer_id, paid) AS (
    VALUES (1, true), (1, true), (2, NULL::boolean)
)
SELECT c.customer_id,
       EXISTS (
           SELECT 1
           FROM invoices AS i
           WHERE i.customer_id = c.customer_id AND i.paid
       ) AS has_paid_invoice
FROM customers AS c
ORDER BY c.customer_id;
```

Results are `1,true`; `2,false`; `3,false`. The correlation selects this customer's invoices. A NULL paid
flag does not satisfy the inner WHERE. Negating the existence test expresses “no paid invoice”.

“Every required item is present” means “there is no required item that is missing”:

```sql
WITH needed(item) AS (VALUES ('bolt'), ('washer')),
packed(item) AS (VALUES ('bolt'), ('bolt'))
SELECT NOT EXISTS (
    SELECT 1
    FROM needed AS n
    WHERE NOT EXISTS (
        SELECT 1 FROM packed AS p WHERE p.item = n.item
    )
) AS complete;
```

The result is false: two bolts do not replace the washer. With an empty `needed` relation, there is no missing
required item, so the result is true. Counting all matching rows would lose this distinction.
Avoid substituting `NOT IN` without considering NULLs: a NULL in its input can make the result unknown.
Read [subquery expressions](https://www.postgresql.org/docs/18/functions-subquery.html).

## 2. Half-Open Intervals and Self-Joins

For intervals `[a_start, a_end)` and `[b_start, b_end)`, there is positive overlap exactly when
`a_start < b_end AND b_start < a_end`. Both inequalities are strict. Joining a relation to itself requires
different aliases so each reference has its own identity.

```sql
WITH slots(slot_id, begins, finishes) AS (
    VALUES (1, 2, 5), (2, 5, 8), (3, 4, 6)
)
SELECT a.slot_id AS slot_a, b.slot_id AS slot_b,
       GREATEST(a.begins, b.begins) AS overlap_start,
       LEAST(a.finishes, b.finishes) AS overlap_end
FROM slots AS a
JOIN slots AS b
  ON a.slot_id < b.slot_id
 AND a.begins < b.finishes
 AND b.begins < a.finishes
ORDER BY a.slot_id, b.slot_id;
```

Results are `(1,3,4,5)` and `(2,3,5,6)`. Slots 1 and 2 only touch at 5. The ID inequality removes both
self-pairs and mirrored duplicates. For a room-specific query, matching the room is an additional condition.
A report-window restriction on each booking is separate from testing overlap between the two bookings.

To find available resources, start from the resource relation and ask whether a conflicting interval
does **not** exist. Starting only from reservations would lose resources with no reservations.
Read [join expressions and aliases](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-JOIN)
and [GREATEST / LEAST](https://www.postgresql.org/docs/18/functions-conditional.html#FUNCTIONS-GREATEST-LEAST).

## 3. Ordered Pages and Matching Cursors

A page needs a unique order. In the following descending order, the first two rows are `(2026-01-05,2)`
and `(2026-01-04,8)`. The second is therefore the continuation cursor for the next two rows:

```sql
WITH editions(edition_id, released_on) AS (
    VALUES (2, DATE '2026-01-05'), (8, DATE '2026-01-04'),
           (9, DATE '2026-01-03'), (4, DATE '2026-01-03')
)
SELECT edition_id, released_on
FROM editions
WHERE (released_on, edition_id) < (DATE '2026-01-04', 8)
ORDER BY released_on DESC, edition_id DESC
LIMIT 2;
```

This returns IDs 9 then 4. The tuple comparison first compares dates, then IDs when the dates tie.
With these non-NULL keys and both directions descending, `<` selects the later page. A mixed-direction order
needs a predicate matching each direction; do not copy this comparison blindly.
Read [row comparisons](https://www.postgresql.org/docs/18/functions-comparisons.html#ROW-WISE-COMPARISON).

The equivalent OFFSET version removes the WHERE clause and uses `LIMIT 2 OFFSET 2`. OFFSET rows still have
to be computed before being skipped; an index does not make a large offset free.
The Practice 11 helper supplies the row immediately **before** the requested page. Copy both its full timestamp
and ID, and measure only the seek query. Acquiring a deep cursor by OFFSET is setup with its own cost.
Frozen data makes the equivalence check straightforward.
Read [LIMIT and OFFSET](https://www.postgresql.org/docs/18/queries-limit.html).

## 4. LAG, Deterministic Order and Time Differences

`LAG` reads a value from the preceding row in its ordered partition. Its default on the first row is NULL.
PostgreSQL retains NULL-valued observations; it does not skip them automatically. A tie-breaker determines
which row is previous when timestamps are equal.

```sql
WITH readings(reading_id, measured_at) AS (
    VALUES (1, TIMESTAMPTZ '2026-01-02 12:00+00'),
           (2, TIMESTAMPTZ '2026-01-02 12:20+00'),
           (3, TIMESTAMPTZ '2026-01-02 12:20+00')
), previous AS (
    SELECT reading_id, measured_at,
           LAG(measured_at) OVER (
               ORDER BY measured_at, reading_id
           ) AS previous_at
    FROM readings
)
SELECT reading_id, measured_at, previous_at,
       EXTRACT(EPOCH FROM measured_at - previous_at) / 60.0 AS gap_minutes
FROM previous
ORDER BY measured_at, reading_id;
```

The gaps are NULL, 20 and 0 minutes. Subtracting timestamps produces an interval; extracting epoch seconds
and dividing by 60 gives total minutes, including fractions. Extracting only the interval's minute field
would lose whole hours. Add `PARTITION BY` when each device or person needs independent history.
Read [LAG](https://www.postgresql.org/docs/18/functions-window.html) and
[date/time arithmetic](https://www.postgresql.org/docs/18/functions-datetime.html).

Filtering changes the history visible to a window. Filtering to a reporting week **before** LAG makes its
first event have no predecessor, even when a real event exists just before the week. An all-history predecessor
would require a different staging choice. Follow the task's boundary rule.

## 5. Build Window Calculations in Stages

A window sees the rows surviving the same query level's FROM, WHERE, GROUP BY and HAVING processing.
To filter, aggregate or apply another window using its output, introduce another query level.
Do not nest a LAG call inside a running SUM at the same level, and do not use a window result in same-level WHERE.

```sql
WITH switches(step, state) AS (
    VALUES (1, 'off'), (2, 'off'), (3, 'on'), (4, 'on')
), previous AS (
    SELECT step, state, LAG(state) OVER (ORDER BY step) AS previous_state
    FROM switches
), flagged AS (
    SELECT step, state,
           CASE WHEN previous_state IS NULL OR state <> previous_state
                THEN 1 ELSE 0 END AS new_run
    FROM previous
), numbered AS (
    SELECT step, state,
           SUM(new_run) OVER (
               ORDER BY step ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS run_no
    FROM flagged
)
SELECT run_no, MIN(step) AS first_step, MAX(step) AS last_step, COUNT(*) AS steps
FROM numbered
GROUP BY run_no
ORDER BY run_no;
```

This returns runs `(1,1,2,2)` and `(2,3,4,2)`. Each stage has one job: predecessor, flag, label, summary.
The input states here are non-NULL; if NULL were a real state, a first-row test would need to distinguish
it from “no predecessor”. In the practice, event timestamps are non-NULL.

The running sum uses integer flags, counts from the first row through the current row, and assigns one
label to every row in a run. In a session report, the flag describes a time gap instead of a state change.
Window ORDER BY controls calculation; final ORDER BY controls presentation. Read the
[window tutorial](https://www.postgresql.org/docs/18/tutorial-window.html).

## 6. Distinct Dates Before Consecutive-Day Groups

Deduplicate a date before asking whether it follows the previous date. Three actions on Tuesday represent
one active date. With UTC set, a `timestamptz` cast to date uses the requested reporting zone.

One way to label consecutive dates is to subtract their ordered row numbers:

```sql
WITH visits(visited_on) AS (
    VALUES (DATE '2026-01-02'), (DATE '2026-01-02'),
           (DATE '2026-01-03'), (DATE '2026-01-06')
), days AS (
    SELECT DISTINCT visited_on FROM visits
), labelled AS (
    SELECT visited_on,
           visited_on - ROW_NUMBER() OVER (ORDER BY visited_on)::integer AS group_key
    FROM days
)
SELECT MIN(visited_on) AS first_day, MAX(visited_on) AS last_day, COUNT(*) AS days
FROM labelled
GROUP BY group_key
ORDER BY first_day;
```

The groups are January 2–3 with two days, and January 6 with one. For consecutive dates, the date and row
number both advance by one, so their difference stays constant. The explicit integer cast matches date-minus-days
arithmetic. For several people, partition the numbering by person and keep that person in the grouping key.
A LAG-based break flag followed by a running sum is another valid method.
Read [ROW_NUMBER](https://www.postgresql.org/docs/18/functions-window.html) and
[date operators](https://www.postgresql.org/docs/18/functions-datetime.html#OPERATORS-DATETIME-TABLE).

## 7. Scalar Subqueries and Empty Aggregates

A scalar subquery occupies one value position: it must return one column and at most one row.
Zero rows give NULL; more than one row is an error. An aggregate without GROUP BY returns one row even
when its input is empty. COUNT gives zero, while MAX gives NULL.

```sql
WITH depots(depot_id) AS (VALUES (1), (2)),
parcels(depot_id, mass) AS (VALUES (1, 4), (1, 7))
SELECT d.depot_id,
       (SELECT COUNT(*) FROM parcels AS p
        WHERE p.depot_id = d.depot_id) AS parcel_count,
       (SELECT MAX(p.mass) FROM parcels AS p
        WHERE p.depot_id = d.depot_id) AS heaviest
FROM depots AS d
ORDER BY d.depot_id;
```

Results are `(1,2,7)` and `(2,0,NULL)`. Each subquery is correlated through the current depot's ID.
Do not remove that predicate or replace the missing maximum with zero unless the report explicitly requires it.
In P12-4, a March count and an all-history maximum intentionally use different time scopes.
Read [scalar subqueries](https://www.postgresql.org/docs/18/sql-expressions.html#SQL-SYNTAX-SCALAR-SUBQUERIES)
and [aggregate functions](https://www.postgresql.org/docs/18/functions-aggregate.html).

## 8. CTE Materialization Is a Plan Choice to Investigate

These declarations name the same small relation using three alternatives:

```sql
WITH quantities AS (SELECT * FROM (VALUES (2), (5)) AS v(n))
SELECT SUM(n) FROM quantities;

WITH quantities AS MATERIALIZED (SELECT * FROM (VALUES (2), (5)) AS v(n))
SELECT SUM(n) FROM quantities;

WITH quantities AS NOT MATERIALIZED (SELECT * FROM (VALUES (2), (5)) AS v(n))
SELECT SUM(n) FROM quantities;
```

All return 7. For an eligible non-recursive, side-effect-free SELECT CTE, PostgreSQL normally folds a
single reference into its parent and normally materializes multiple references. `MATERIALIZED` requests
separate computation; `NOT MATERIALIZED` permits folding and joint optimization, potentially repeating work.
The latter does not apply to recursive or side-effecting CTEs, including SELECTs containing volatile functions.

Materialization can share an expensive calculation, but outer filters may no longer narrow the underlying
scan as effectively. Folding can make different restrictions and base-table index paths available at each use.
A CTE is not a permanent indexed table; an index on its source does not index a materialized intermediate result.
Neither keyword guarantees a faster query or a particular node.

P12-4 deliberately references one CTE twice. Keep the source columns, correlations and time scopes unchanged
while comparing declarations, then test an index with one declaration fixed. Read
[CTE materialization](https://www.postgresql.org/docs/18/queries-with.html#QUERIES-WITH-CTE-MATERIALIZATION).

## 9. ROWS and RANGE Count Different Contributors

Aggregate events into daily counts before calculating a daily moving average.
`ROWS` counts positions in the ordered input. A time-based `RANGE` includes observations within a distance
of the current ordering value.

```sql
WITH daily(day, visits) AS (
    VALUES (DATE '2026-01-01', 2), (DATE '2026-01-02', 4), (DATE '2026-01-05', 12)
)
SELECT day, visits,
       AVG(visits) OVER (
           ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS last_three_observations,
       AVG(visits) OVER (
           ORDER BY day::timestamp
           RANGE BETWEEN INTERVAL '2 days' PRECEDING AND CURRENT ROW
       ) AS last_three_calendar_dates
FROM daily
ORDER BY day;
```

On January 5, the observation average is 6; the calendar-range average is 12 because only January 5 is
observed within January 3–5. Neither calculation inserts the missing dates. A zero-filled calendar would
answer a different question.

An interval-offset RANGE needs one suitable timestamp ordering expression. Here there is one row per date,
and converting to midnight makes the date boundary explicit. With peers, the default ordered frame can include
all rows sharing the current ordering value; explicit ROWS and a unique order avoid ambiguity in running flags.
Read [window frames](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-WINDOW-FUNCTIONS).

## 10. Expression and Composite Index Hypotheses

For an existing example table, the following definitions index different values:

```sql
CREATE INDEX publishers_name_idx ON sample.publishers (publisher_name);
CREATE INDEX publishers_folded_name_idx ON sample.publishers (lower(publisher_name));
```

A query testing `lower(publisher_name) = 'north press'` can use the computed expression as an index key.
An ordinary index stores the original name. Keep the query fixed and compare the two candidates separately.
The expression index also has storage and write-maintenance costs. These statements illustrate DDL;
the unrelated `sample.publishers` table is not part of the course fixture.
Read [expression indexes](https://www.postgresql.org/docs/18/indexes-expressional.html).

For composite B-trees, ask which leading keys have equality conditions, which range narrows the scan,
and which order the query requests. An interval-overlap test uses two bounds; a candidate may narrow one
while leaving the other as a filter. PostgreSQL 18 can also consider skip scans in suitable cases, so an
absent leading condition is not proof an index is unusable. Inspect the observed plan.
Read [multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html).

## 11. Measure One Change at a Time

For each fixed query: baseline result and warm-up, baseline plan, candidate index plus ANALYZE,
same result and warm-up, then indexed plan. Put `EXPLAIN (ANALYZE, BUFFERS)` immediately before the whole
SELECT statement, before WITH when CTEs are present.

Inspect access conditions, remaining filters, row counts and loops, plus Sort, WindowAgg, Aggregate or CTE
work. Few returned rows do not imply little input work. Shared reads are requests into PostgreSQL buffers,
not guaranteed physical disk reads. Do not add inclusive parent and child buffer counts as independent totals.
Instrumented execution time varies; use the plan's work to support the explanation.

The [P9/P10 plan guide](practices-09-10-sql-guide.md) gives the compact field reference.
Read [Using EXPLAIN](https://www.postgresql.org/docs/18/using-explain.html) for PostgreSQL's interpretation.
Keep query-rewrite comparisons under fixed indexes separate from fixed-query index comparisons.

## 12. Check Complete Results and Save Evidence

Matching row counts alone cannot prove equality. Check **values and duplicate counts**, then check the
declared final order. These unrelated inventory examples separate those questions. Each has two bolts
and one washer; the washer's quantity is NULL. The second result moves the washer to the first position.

### Compare Values and Duplicate Counts

```sql
WITH before_result(position, item, quantity) AS (
    VALUES (1, 'bolt', 2), (2, 'bolt', 2), (3, 'washer', NULL::integer)
), after_result(position, item, quantity) AS (
    VALUES (1, 'washer', NULL::integer), (2, 'bolt', 2), (3, 'bolt', 2)
), differences AS (
    (SELECT item, quantity FROM before_result
     EXCEPT ALL
     SELECT item, quantity FROM after_result)
    UNION ALL
    (SELECT item, quantity FROM after_result
     EXCEPT ALL
     SELECT item, quantity FROM before_result)
)
SELECT NOT EXISTS (SELECT 1 FROM differences) AS same_rows;
```

This returns true: order does not participate in this comparison. Remove one bolt from the second
result and it returns false. `ALL` preserves the missing duplicate; ordinary `EXCEPT` would hide it.
Both directions matter because either result can contain extra rows. NULL matches NULL for these set
operations. Two empty results also compare equal. Read [set operations](https://www.postgresql.org/docs/18/queries-union.html).

### Compare Saved Positions and NULL Values

```sql
WITH before_result(position, item, quantity) AS (
    VALUES (1, 'bolt', 2), (2, 'bolt', 2), (3, 'washer', NULL::integer)
), after_result(position, item, quantity) AS (
    VALUES (1, 'washer', NULL::integer), (2, 'bolt', 2), (3, 'bolt', 2)
)
SELECT NOT EXISTS (
    SELECT 1
    FROM before_result AS b
    FULL JOIN after_result AS a ON a.position = b.position
    WHERE b.position IS NULL OR a.position IS NULL
       OR ROW(b.item, b.quantity) IS DISTINCT FROM ROW(a.item, a.quantity)
) AS same_order;
```

This returns false: the same values occupy different positions. The FULL JOIN also exposes a missing
position on either side. `IS DISTINCT FROM` treats two NULLs as matching and distinguishes NULL from zero
or empty text. Ordinary `<>` can return unknown for NULL and miss a difference. Read
[comparison predicates](https://www.postgresql.org/docs/18/functions-comparison.html).

### Apply the Checks to Your Reports

In the **same SQL connection**, save a typed temporary baseline before index DDL and an indexed
snapshot afterwards. These snapshots support the **values and duplicate counts** check only. Here is
an outline to adapt; angle-bracket parts are deliberately unfinished:

```text
CREATE TEMP TABLE evidence_before AS
SELECT q.*
FROM (<your unchanged report SELECT, without its final semicolon>) AS q;

-- After installing the candidate, capture evidence_after using the same SELECT.
```

Replace the first example's input CTEs with reads from your two snapshots and replace `item, quantity`
with **all report columns** in matching types. Both directions of `EXCEPT ALL` must be empty.
Temporary tables live outside `advanced_lab` and disappear when the connection closes. If you reconnect,
capture both again. Use distinct names per task or remove your own earlier snapshots before reuse.

A saved table has no guaranteed presentation order. For the **returned-order** check, compare the raw
CSV exports below without sorting or opening and re-saving them in a spreadsheet. Do not assign positions
by sorting each result again: that can conceal a reversed report or a missing tie-breaker. The positional
SQL example is valid only when its positions record the actual client-returned sequence. Matching exports
show that the two observed sequences agree; also inspect the final `ORDER BY` against the task's complete
order, including tie-breakers. Two executions can otherwise agree on the same incorrect order.

Snapshot capture and comparison are separate from measurement. Warm up and measure the original SELECT
unchanged, without the snapshot wrapper or COPY. Cursor acquisition is separate setup too. Keep results,
plans, configuration labels and your explanation under `work/`, using task and configuration names.

### Export Results and Plans

In pgAdmin, execute the task SELECT with UTC set and save the complete Data Output grid as CSV under the
host package's `work/` directory. Run `EXPLAIN (ANALYZE, BUFFERS)` separately and save the complete plan text.
A plan does not contain actual result rows. For the reproducible sequence check, use the terminal route
below even if you author the query in pgAdmin; its fixed export settings preserve NULL distinctions.

Put this outline in `work/P11-1-export.sql`, replacing the placeholder with your completed task SELECT,
including its own final `ORDER BY` and parameters but without its final semicolon:

```text
SET TIME ZONE 'UTC';
SET DateStyle = 'ISO, YMD';
SET client_encoding = 'UTF8';
COPY (
<your unchanged report SELECT, without its final semicolon>
) TO STDOUT WITH (FORMAT csv, HEADER true, NULL '\N', FORCE_QUOTE *);
```

Keep these settings, column names/types and COPY options identical for baseline and indexed captures.
COPY quotes every non-NULL value: SQL NULL is unquoted `\N`, empty text is `""`, and literal backslash-N
text is `"\N"`. Embedded commas, quotes and newlines are escaped as CSV. See the
[PostgreSQL COPY reference](https://www.postgresql.org/docs/18/sql-copy.html).

Put the original query's EXPLAIN version and UTC setup in `work/P11-1-plan.sql`. From the host
`course-environment` directory, run:

```sh
docker compose exec -T db psql -X -q -v ON_ERROR_STOP=1 -U student -d university \
  -f /work/P11-1-export.sql > work/P11-1-baseline-results.csv
docker compose exec -T db psql -X -q -v ON_ERROR_STOP=1 -U student -d university \
  -f /work/P11-1-plan.sql > work/P11-1-baseline-plan.txt
```

Check that each command succeeds. After installing the candidate, repeat with the unchanged export file
and save to `work/P11-1-indexed-results.csv`. In a macOS/Linux/WSL host terminal, compare complete files:

```sh
cmp work/P11-1-baseline-results.csv work/P11-1-indexed-results.csv
```

No output with exit status 0 means identical bytes, including row sequence, duplicate counts and NULL
encoding. A difference gives status 1; an unreadable/missing file is an error, not an equality result.
On Windows Command Prompt use `fc /b work\P11-1-baseline-results.csv work\P11-1-indexed-results.csv`
instead. Retain both files and investigate any difference. Require **both** the typed values check and
this raw sequence check to pass. Empty reports retain the same header and compare equal.

The host shell's `>` writes files into host `work/`; psql `\o` inside the database container would write
a container path, and the database's `/work` mount is read-only. Keep one task/variant per export to avoid
mixing grids. See the [client workflow guide](query-and-script-workflows.md) and
[psql reference](https://www.postgresql.org/docs/18/app-psql.html) for file handling.
