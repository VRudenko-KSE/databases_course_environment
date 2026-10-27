# Practices 13–14: Optional Reference and Replays

Nothing here is required to finish the core practice tasks. Use this reference after completing
and explaining your repairs, or when a TA helps investigate an unexpected result. No extra capture
or homework is implied. The [core handout](practices-13-14.md) defines the required work.

## Extra CTE Behavior

These examples are optional. They explain limits of the simple linkage pattern rather than adding
requirements to P13-2. Run each whole block outside an existing transaction.

## 4. The Returned Relation and the Base Table Are Different Views

Data-modifying CTE components share a statement snapshot; do not depend on sibling write order.
Read a CTE's returned relation to communicate its new rows to another part of the statement.

<!-- example: cte_visibility -->

```sql
BEGIN;
CREATE TEMP TABLE guide_prices (item_id integer PRIMARY KEY, price integer);
INSERT INTO guide_prices VALUES (1,4);
WITH changed AS (
    UPDATE guide_prices SET price=price+1 WHERE item_id=1 RETURNING price
)
SELECT (SELECT price FROM guide_prices WHERE item_id=1) AS base_snapshot,
       (SELECT price FROM changed) AS returned_value;
SELECT price FROM guide_prices WHERE item_id=1;
ROLLBACK;
```

The combined result is `(4,5)`; the next statement sees 5. Do not interpret textual WITH order
as a sequence of independently visible commits. Avoid modifying the same row twice in one
statement. Materialization tuning from P12 does not turn a modifying CTE into a concurrency protocol.

## 5. A Write CTE Executes Even When Its Output Is Unused

<!-- example: unconsumed_cte -->

```sql
BEGIN;
CREATE TEMP TABLE guide_outbox (message_id integer PRIMARY KEY);
INSERT INTO guide_outbox VALUES (1);
WITH removed AS (
    DELETE FROM guide_outbox RETURNING message_id
)
SELECT 'done' AS label;
SELECT count(*) FROM guide_outbox;
ROLLBACK;
```

The first result says `done`, and the count is zero. The modifying CTE executes to completion
even though the outer SELECT never reads `removed`. A harmless-looking SELECT outside a write
CTE can therefore still change data. Check the entire statement before executing it.

## 6. Empty RETURNING Can Leave a Workflow Incomplete Without an Error

<!-- example: empty_cte -->

```sql
BEGIN;
CREATE TEMP TABLE guide_pending (job_id integer PRIMARY KEY);
CREATE TEMP TABLE guide_done (job_id integer PRIMARY KEY);
INSERT INTO guide_pending VALUES (1);
WITH removed AS (
    DELETE FROM guide_pending WHERE job_id=999 RETURNING job_id
)
INSERT INTO guide_done SELECT job_id FROM removed RETURNING job_id;
SELECT (SELECT count(*) FROM guide_pending), (SELECT count(*) FROM guide_done);
ROLLBACK;
```

The INSERT returns no rows; final counts are `(1,0)`. No SQL error occurred, but job 1 was not
completed. Decide what the business operation requires and verify affected rows. Neither
RETURNING nor grouping SQL into one statement automatically implements an undeclared invariant.

## Optional Replays and Transfer of Fixes

These extensions reuse the current fixtures. Save your work and finish both transactions, then use
the relevant Reset file before and after each experiment. No additional migrations are needed.

- **Unsafe admission replay:** reset `p13_locking`. Let both Read Committed checks finish before
  inserting distinct learners without the parent lock. Compare the final rows with your protected run.
- **Stable rota replay:** reset `p14_serializable`. Use Repeatable Read and establish both counts
  before changing I-A and I-B separately. Compare this with your Serializable repair.
- **Rota lock transfer:** reset `p14_serializable`, use Read Committed, and coordinate on the existing
  exam row. Count in a separate statement after locking. Compare waiting with retrying.
- **CTE error comparison:** reset `p13_cte`, then change the final state in a copy of your repaired
  CTE to `invalid`. Inspect both tables after the CHECK error.

Full completed repairs remain private TA material. Counter and deadlock ordering remain supplied
reasoning examples; they do not require additional installed schemas. No optional replay displaces
consultation or extends the core completion checklist.

## Optional Wait Observer

Use a third connection only if useful; label A/B with `SET application_name='mini_A';` / `mini_B`.
The core tasks need only two writing connections and their simple final checks.

```sql
SELECT pid,application_name,state,pg_blocking_pids(pid) AS blocked_by
FROM pg_stat_activity
WHERE datname=current_database() AND application_name IN ('mini_A','mini_B')
ORDER BY application_name,pid;
```

This is a read-only diagnostic, not a compulsory submission. Use backend PIDs to distinguish any
old sessions with the same label. Do not cancel other learners' sessions or change shared settings.
