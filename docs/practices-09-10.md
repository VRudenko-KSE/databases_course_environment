# Practices 9–10: Indexes, Reports, and Query Plans

Use one prepared university dataset for both practices. Each session has **four core tasks and one optional task**.
The core workshop lasts 60 minutes; minutes 60–80 remain Assignment 2 studio time.
Work in pairs, switch keyboard/explainer roles after each task, and save your own explanation.

## Prepare Before Practice 9

The default seed is **2,000,000 enrolments**, with 100,000 students, 500 courses, and 10,000 offerings.
It is deterministic fictional teaching data, separate from all earlier schemas. There is one profile.
New empty-volume Compose installations load migration `60-practices-09-10.sql` automatically.
For an existing installation, update the package files, start the services, and open container `psql`:

```sh
docker compose up -d --wait
docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university
```

Check whether the new table exists:

```sql
SELECT to_regclass('index_lab.enrolments');
```

Only if that result is NULL, exit `psql` with `\q`. From the `course-environment` directory in your terminal,
run this Docker command to apply the migration once:

<!-- rumdl-disable MD013 -->

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/migrations/60-practices-09-10.sql
```

<!-- rumdl-enable MD013 -->

Reopen `psql` using the command above and confirm the starting state:

```sql
SELECT COUNT(*) AS enrolments FROM index_lab.enrolments;
SELECT COUNT(*) AS students FROM index_lab.students;
SELECT indexname, indexdef FROM pg_indexes
WHERE schemaname = 'index_lab' AND tablename = 'enrolments'
ORDER BY indexname;
```

Expect 2,000,000 enrolments, 100,000 students, and the primary-key and unique-constraint indexes.
If an older 200,000-row version is already installed, save any P9/P10 work and use the scoped full checkpoint
below to replace only `index_lab`/`index_write`, then repeat the checks. Restarting Docker does not replay migrations.
Exit `psql` with `\q`, refresh the schemas in your SQL client, and open the relevant starter:
[Practice 9](../work/practice-09.sql) or [Practice 10](../work/practice-10.sql).
Do not recreate the whole Docker volume to add this fixture. Custom database usernames/names require matching flags.

## Dataset and Report Meaning

<!-- rumdl-disable MD013 -->

| Table | One Row Means | Columns Used |
|---|---|---|
| `index_lab.students` | One fictional student | `student_id, full_name` |
| `index_lab.courses` | One catalogue course | `course_id, title` |
| `index_lab.offerings` | One offering of a course | `offering_id, course_id, semester` |
| `index_lab.enrolments` | One student–offering registration | `enrolment_id, student_id, offering_id, registered_at, status, grade, registration_note` |
| `index_lab.ingest_batch` | One supplied new registration for the write experiment | Same columns as enrolments; 1,000 rows |

<!-- rumdl-enable MD013 -->

Each student has 20 registrations; `(offering_id, student_id)` is unique. Offering 10000 has no registrations.
The baseline already has indexes for the primary key and that unique constraint. Baseline does not mean no indexes.
Status is `completed`, `active`, or `cancelled`. Only completed registrations have grades; zero is a valid grade.
Status describes the supplied current snapshot, not a status-change event history. A March cancellation count here means
currently cancelled registrations whose registration date falls in March, not cancellations that occurred in March.

Dates cover January–June 2026 in UTC. There are explicit month-boundary rows, a quiet March 4, tied grades,
and tied registration timestamps. Use fixed dates, not today's date. In every SQL connection run:

```sql
SET TIME ZONE 'UTC';
```

The data contains common and rare statuses, but most offerings have similar sizes. This is an experiment fixture,
not a claim about a real university's population or workload.

## Fair Experiments and Saved Evidence

Read the [SQL and plan guide](practices-09-10-sql-guide.md) before the first experiment.
P9-1 and P10-1 provide a recommended index for a guided first comparison. In every later task, choose and justify
an index for that query, create it, and measure the difference. The optional tasks use the same workflow.
"Without" means without your added candidate; primary-key and unique-constraint indexes stay in place.
`ANALYZE` refreshes planner statistics; `EXPLAIN (ANALYZE, BUFFERS)` executes the query and measures its plan.

For each named query variant:

1. Restore the index baseline with the supplied reset below. Keep constraint indexes.
2. Write and execute the SELECT normally. Check its row grain, boundaries, NULLs, ties and ordering.
3. Record a prediction, run the SELECT once as a read warm-up, then capture `EXPLAIN (ANALYZE, BUFFERS)`.
4. Add only the candidate index being tested and run `ANALYZE index_lab.enrolments;`.
5. Repeat the same SELECT warm-up and plan capture. Confirm that the actual result is unchanged.
6. Calculate the execution-time difference as indexed minus baseline milliseconds, and compare buffers at the same
   relevant node (or both complete-query totals). Negative time difference means the indexed run was faster.
   Save the SQL, index definition, parameters, both plans, results, measured differences and a two-sentence explanation.

For two candidate designs, return to baseline between them. Do not leave a competing experimental index installed.
The original constraint indexes remain legitimate alternatives in every configuration.
Keep the data, query, client session settings and comparison order consistent. A changed predicate is a separate variant
with its own before/after pair. Shared hits/reads, emitted rows, loops and remaining work support your explanation;
elapsed time alone is insufficient. No particular plan node or minimum speedup is required.

Use this compact evidence table for each experiment:

<!-- rumdl-disable MD013 -->

| Query / Parameters | Configuration | Main Access Path | Rows / Loops | Shared Hits / Reads | Time | Index Bytes | Explanation |
|---|---|---|---|---|---|---|---|
| Your labelled query | baseline / candidate | Observed node | Named node's values | Named node's values | Observed ms | Measured bytes | Work changed and work remaining |

<!-- rumdl-enable MD013 -->

Capture actual results separately: `EXPLAIN ANALYZE` executes the query but does not display its result rows.
Save files under `work/`, with task/configuration labels. Preserve predictions even when observations disagree.

## Practice 9: Single-Column and Partial Indexes

The three teaching theses and observable outcomes are:

1. **Ordered entries provide a route to records.** Trace a supplied lookup/range, distinguishing index pages,
   table-page requests and buffer reads.
2. **An index changes an access option, not the report's meaning.** Produce a correct report and a comparable
   before/after plan pair with unchanged results.
3. **The matching share affects useful access choices.** Explain a rare/common comparison using rows and buffers,
   including a defensible scan when an index exists.

<!-- rumdl-disable MD013 -->

| Task | Status | Execute | Explain and Save |
|---|---|---|---|
| **P9-1 — Inspect the larger university** | Core | Start from all offerings, join courses, and left join enrolments. Return `offering_id, title, semester, enrolment_count, graded_count, average_grade`, ordered by offering ID. Count a non-NULL enrolment key, count non-NULL grades, and round the average to two decimals. Keep empty offerings. Run this query WITHOUT the recommended P9-1 index below and save `EXPLAIN (ANALYZE, BUFFERS)`. Create that index, run the identical query WITH it, and save the second plan. | Reconcile the sum of enrolment counts with the seed size. Trace offering 10000 and distinguish zero registrations, a NULL average, and grade zero. Compare both plans, execution time and buffers; calculate the measured difference and verify unchanged results. Explain which constraint indexes were present in both configurations. |
| **P9-2 — Find one student's transcript** | Core | For student 42, join enrolments to offerings and courses. Return `enrolment_id, offering_id, title, semester, registered_at, status, grade`, ordered by registration time then enrolment ID. Find a suitable index for this query and justify its columns. Measure the query without your candidate, create it, and repeat the identical query with it using `EXPLAIN (ANALYZE, BUFFERS)`. | Check 20 unchanged detail rows and calculate the time/buffer differences. Annotate access path, conditions or filters, emitted rows and loops. Before execution, trace lookup 30 and inclusive range 30–60 in the supplied tree. Distinguish the tree model from the real plan. |
| **P9-3 — Count registrations by date** | Core | Select `[2026-03-01 00:00:00+00, 2026-04-01 00:00:00+00)`. Group by UTC registration date and return `activity_date, enrolment_count, cancelled_count`; use a conditional aggregate for cancellations. Order by date, retaining only dates with activity. Find a suitable index, explain your choice, capture a plan without it, create it, and measure the identical query with it. | Check the boundary rows and missing March 4. Reconcile totals with eligible registrations and explain the snapshot status metric. Compare both `EXPLAIN (ANALYZE, BUFFERS)` outputs, time and buffers; identify scan, aggregation and sort work that remains. |
| **P9-4 — Explain a rare/common contrast** | Core | Count enrolments per offering, ordered by offering ID, first for `status = 'cancelled'`, then for `status = 'completed'`. Find an index you expect to help this workload. Measure both fixed variants without your candidate, create it, and measure both again with it. Keep a separate before/after plan pair for each variant. | Calculate both matching shares and the time/buffer differences from `EXPLAIN (ANALYZE, BUFFERS)`. Explain estimated versus actual rows and why the observed route can differ by status. An available index need not be chosen. Save the P9 individual exit answer. |
| **P9-5 — Index only cancellations** | Optional | For cancelled registrations in the March interval, return `enrolment_id, offering_id, registered_at`, ordered by timestamp then ID. Find suitable index keys and design a partial predicate for this query. Measure the baseline, create your partial index and measure again. Compare with a full index using your chosen keys, restoring baseline between candidates. Also test the completed-status variant with only the partial candidate installed. | Save before/after `EXPLAIN (ANALYZE, BUFFERS)` plans and calculate time/buffer differences. Compare index sizes and unchanged matching-query results. Explain which rows are absent from the partial index and why its predicate matters for the completed-status query. |

<!-- rumdl-enable MD013 -->

### Recommended Index for P9-1

First execute your report without this added index, including its warm-up and
`EXPLAIN (ANALYZE, BUFFERS)` capture. Then create the recommended index:

```sql
CREATE INDEX p9_offering_report ON index_lab.enrolments (offering_id)
INCLUDE (enrolment_id, grade);
ANALYZE index_lab.enrolments;
```

Repeat exactly the same report and plan capture WITH the index. It groups entries by offering and also stores
values needed for the counts and average, giving PostgreSQL an alternative to reading the wider table.
`INCLUDE` stores those additional values without making them search keys; P10's optional task explores this further.
Compare the observed plan and measured difference even if PostgreSQL keeps the same access path.
Drop this candidate with the supplied index reset before P9-2.

Supplied tree: root separator **40**, leaves `[10, 20, 30] → [40, 50, 60]`.
Keys below 40 go left; keys at least 40 go right. Leaves refer to separate table records.
Do not invent table-page counts when their record locations have not been supplied.

## Practice 10: Composite Indexes and Workload Choices

The three teaching theses and observable outcomes are:

1. **Composite order should fit predicates and ordering.** Compare two key orders and explain their observed work.
2. **An index's value depends on the report.** Preserve ranking/calendar semantics and identify work that remains.
3. **Read benefit has storage and maintenance costs.** Recommend at most two indexes, supported by read plans,
   index sizes, a controlled write comparison, and a workload change that would alter the choice.

<!-- rumdl-disable MD013 -->

| Task | Status | Execute | Explain and Save |
|---|---|---|---|
| **P10-1 — Retrieve the latest 20 registrations** | Core | For offering 101, return `enrolment_id, student_id, registered_at, status`, ordered by timestamp descending then enrolment ID descending, limited to 20. First run WITHOUT the recommended P10-1 index below and capture `EXPLAIN (ANALYZE, BUFFERS)`. Create it, run the same query WITH it, and capture the new plan. Then choose and test an alternative column order from baseline. | Trace the timestamp tie at the selection boundary. Compare both plans, execution time and buffers; calculate the difference and verify unchanged winners/order. Explain which key order groups one offering's entries and what sorting remains. Predict the effect of a time-only request. |
| **P10-2 — Select exactly three students per offering** | Core | Exclude NULL grades. In a CTE, calculate ROW_NUMBER per offering ordered by grade descending then student ID. Outside it retain positions 1–3; return `offering_id, student_id, grade, position`, ordered by offering then position. Find a suitable index and justify its keys/order. Measure the query without it, create it, and repeat the same query with it. | Compare `EXPLAIN (ANALYZE, BUFFERS)`, execution time and buffers, retaining the same winners. Trace offering 101's third-place tie and explain the different membership under grade-only RANK. Identify remaining scan, sort and WindowAgg work; few output rows do not imply few examined rows. |
| **P10-3 — Restore quiet days and a running total** | Core | Aggregate registrations for March 1–7 inclusive in a daily CTE. Generate all seven dates, left join counts, and replace missing counts with zero. Return `activity_date, enrolment_count, running_count` in date order, using a running SUM with an explicit ROWS frame. Find an index that could help this query, measure without it, create it, and measure the identical query with it. | Check March 4 has zero and an unchanged running total; reconcile the final total with the week's input. Compare both `EXPLAIN (ANALYZE, BUFFERS)` outputs and calculate time/buffer differences. Explain aggregation before windows, the frame and why an index cannot create missing dates. |
| **P10-4 — Recommend two indexes and measure their cost** | Core | Find and justify at most two useful indexes for the supplied workload, using your earlier experiments. Measure P9-2 and P10-1 without the portfolio, create the chosen indexes, and measure both queries with the final combined portfolio. Follow the write protocol to measure the same 1,000-row scratch INSERT without and with matching portfolio indexes, rebuilding scratch before each configuration. Record sizes. | Compare baseline/indexed `EXPLAIN (ANALYZE, BUFFERS)` plans and calculate time/buffer differences for both SELECTs and the INSERT. Name each index's benefit, a report it does not solve, its storage/write costs and a changed-demand scenario. Negative or negligible gains are valid findings. Save the individual exit answer. |
| **P10-5 — Cover the transcript** | Optional | Reuse P9-2 unchanged. Find a suitable plain lookup index and a covering alternative; choose the key and INCLUDE columns needed by the query. Measure without either candidate, then create and measure each candidate independently from baseline. Justify the included columns rather than copying every table column. | Compare both candidates against baseline using `EXPLAIN (ANALYZE, BUFFERS)`, time/buffer differences and index bytes. Inspect Index Only Scan and Heap Fetches when present. Coverage applies to enrolments; dimension joins still access other tables, and visibility can still require heap fetches. |

<!-- rumdl-enable MD013 -->

### Recommended Index for P10-1

Capture the latest-20 query WITHOUT this added index. Then create:

```sql
CREATE INDEX p10_recent ON index_lab.enrolments
    (offering_id, registered_at DESC, enrolment_id DESC);
ANALYZE index_lab.enrolments;
```

Repeat the identical query WITH the index, including the same warm-up and `EXPLAIN (ANALYZE, BUFFERS)` capture.
Compare execution time, buffers, conditions and sorting. Equality on offering ID comes before the required
registration-time/ID order. Next design an alternative order and test it independently from baseline.
Use the index reset before P10-2 so later choices and measurements are your own.

Before P10-1, sort `(A,1),(A,3),(A,5),(B,2),(B,4),(B,6)` by `(device,time)` and `(time,device)`.
Mark A with time at least 3, then mark time at least 3 regardless of device. Explain how the useful grouping changes.

## P10-4 Workload and Write Protocol

Assume a student portal runs 80 transcript requests and 15 latest-offering requests for every five calendar reports,
and imports 1,000 new registrations each hour. These are supplied workload assumptions, not measured demand.
Use the earlier plans as the selection evidence. Keep the two chosen definitions unchanged across the final reads
and scratch write experiment; primary/unique constraint indexes do not count toward the two-index limit.

Use `index_lab.enrolments` only for reads. Write only to `index_write.enrolments`.
The supplied reset creates a logged scratch copy with the same historical rows, columns, constraints
and constraint indexes. It deliberately omits all experimental indexes. The batch has new IDs and valid
student/offering pairs.

1. Reset experimental indexes; capture the two baseline reads if not already saved. Rebuild scratch using the command
   below. Count its rows once as a read warm-up, and run the size script.
2. Write one INSERT with explicit columns, selecting all rows from `index_lab.ingest_batch` in enrolment-ID order.
   Execute it **once**, prefixed by `EXPLAIN (ANALYZE, BUFFERS)`, with autocommit enabled.
3. Count scratch rows afterward and record sizes: 2,000,000 must become 2,001,000.
   Do not rerun the INSERT for its row count.
4. Rebuild scratch from the historical source again. Add your two final indexes to the main table and equivalent
   definitions to scratch. Match columns, directions, predicates and INCLUDE columns. Run ANALYZE on both tables.
5. Capture the two final read plans after the same read warm-ups. Repeat the scratch count warm-up and before sizes,
   the identical measured INSERT once, then the after count and sizes.

**EXPLAIN ANALYZE executes and commits the INSERT with autocommit on.** Every retry needs a fresh scratch rebuild;
deleting the batch is not an equivalent reset. If a statement errors or its execution is uncertain, stop and rebuild.
Setup, copying, index creation and ANALYZE are outside the measured INSERT. Its instrumented time is not an end-to-end
ingestion throughput measurement. A TA checkpoint can supply saved plans if execution blocks the class; run your own
experiment later and label supplied evidence honestly.

## Resets and Size Checks

Save SQL and evidence first. Open the container `psql` command shown above, then choose the relevant command.
These `\i` commands are for `psql`, not pgAdmin's Query Tool.

```text
-- Start an independent index experiment: removes added indexes, preserves rows and constraints.
\i /course/sql/practices-09-10-reset-indexes.sql

-- Before each measured INSERT: discards and rebuilds only the scratch schema.
\i /course/sql/practices-09-10-reset-write.sql

-- Inspect individual definitions/sizes and separate table/index/total bytes.
\i /course/sql/practices-09-10-sizes.sql

-- Full P9/P10 recovery: discards edits in index_lab and index_write and recreates the seed.
\i /course/sql/practices-09-10-checkpoint.sql
```

The full checkpoint preserves earlier practice schemas and host work files. It removes the added indexes from P9;
P10 intentionally starts from the same constraint-only baseline. Keep P9 evidence before using it.
On a shared database, the TA coordinates resets and index creation for the whole group; independently measured
experiments require separate database instances or instructor-assigned isolated copies.

## Timing, Checkpoints, and Handoff

<!-- rumdl-disable MD013 -->

| Minutes | Practice 9 | Practice 10 | Evidence Checkpoint |
|---|---|---|---|
| 0–15 | Audit data without/with the recommended index (P9-1) | Latest query without/with the recommendation, then an alternative order (P10-1) | C15: unchanged report, paired plans and measured differences |
| 15–30 | Trace the tiny tree; test transcript index (P9-2) | Top-three report and window plan (P10-2) | C30: unchanged results and annotated plan pair |
| 30–45 | Date report and your chosen index (P9-3) | Complete calendar and running total (P10-3) | C45: boundary/quiet-day checks and plan pair |
| 45–60 | Rare/common contrast and exit (P9-4) | Portfolio, prepared write experiment and exit (P10-4) | C60: counterexample / recommendation, costs and saved state |
| 60–80 | Assignment 2 correctness and baseline studio | Assignment 2 composite-index and read-plan studio | Individual progress, feedback and next action |

<!-- rumdl-enable MD013 -->

Each 15-minute cycle allocates about ten minutes to the brief demonstration, writing/running and help, then five
to solution comparison. Exit questions fit the final cycle. If blocked, use a TA hint, a partial query, then a saved
checkpoint to join the next task. Mark which execution still needs follow-up. No work is required during the break.
Optional P9-5/P10-5 are for early finishers or later study and never displace the studio; they are not extra core tasks
or automatically awarded bonus points.

P9 exit: **Why can PostgreSQL reasonably scan a table even when an index exists?**
P10 exit: **Which query justifies one of your indexes, what does it cost, and what workload change weakens the choice?**
Reuse the P10 exit at the opening of Practice 11. Keep practice work separate from Assignment 2 submissions.
