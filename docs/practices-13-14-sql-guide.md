# Short SQL Guide for Practices 13–14

Use these examples when completing the [student blocks](practices-13-14.md). They use unrelated
temporary tables and do not complete the practice repairs. Run each example as a whole selection,
outside an existing transaction. The core practice needs only the mechanisms on this page.

## Work With One Block at a Time

Open independent A/B connections to the same database; verify different `pg_backend_pid()` values.
In pgAdmin use separate Query Tools; in DBeaver/PyCharm use genuinely separate sessions, not just
tabs sharing one connection. Keep autocommit ON outside explicit BEGIN/COMMIT blocks.

The starter's SQL templates are commented for safety. Copy just the SQL between one `@block`
label and `@endblock` into its named connection, uncomment it with the editor's Toggle Comment
command, fill its TODOs and execute that selection. Keep blocks separate: combining several
handoffs into one selection changes the experiment. When B waits, leave it running and switch
back to A. After the transactions finish, A can run the supplied final check; no observer is needed.

## 1. RETURNING Shows Affected Rows

<!-- example: returning -->

```sql
BEGIN;
CREATE TEMP TABLE guide_parcels (parcel_id integer PRIMARY KEY, weight integer);
INSERT INTO guide_parcels VALUES (7,2) RETURNING parcel_id,weight;
UPDATE guide_parcels SET weight=weight+1 WHERE parcel_id=7 RETURNING parcel_id,weight;
ROLLBACK;
```

The two results describe the inserted and updated row. The arithmetic expression is evaluated
against the database row. RETURNING gives values without a separate lookup; it does not commit.

## 2. Choose the Transaction Boundary

BEGIN starts an atomic unit; COMMIT completes it; ROLLBACK undoes it. An error inside the unit
leaves it failed until you roll it back. Keep P13-1's deliberate fault in its own numbered block.

<!-- example: returned_then_rollback -->

```sql
BEGIN;
CREATE TEMP TABLE guide_balance (account_id integer PRIMARY KEY, amount integer);
INSERT INTO guide_balance VALUES (8,2);
COMMIT;
BEGIN;
UPDATE guide_balance SET amount=4 WHERE account_id=8 RETURNING amount;
ROLLBACK;
SELECT amount FROM guide_balance WHERE account_id=8;
DROP TABLE guide_balance;
```

The UPDATE returns 4, but the final read returns 2. Setup is explicitly committed so this works
when a GUI sends the example as one whole query string. Returned rows are not a commit acknowledgement.

## 3. Pass a Returned Key to Another Write

Here an INSERT returns a key and a main UPDATE consumes it. This has the same SQL shape as the
CTE exercise, but uses unrelated inventory items and issue records.

<!-- example: modifying_cte -->

```sql
BEGIN;
CREATE TEMP TABLE guide_items (item_id integer PRIMARY KEY, issued boolean);
CREATE TEMP TABLE guide_issues (issue_id integer PRIMARY KEY, item_id integer);
INSERT INTO guide_items VALUES (9,false);
WITH issued_row AS (
    INSERT INTO guide_issues VALUES (90,9) RETURNING item_id
)
UPDATE guide_items AS i SET issued=true
FROM issued_row AS r
WHERE i.item_id=r.item_id
RETURNING i.item_id,i.issued;
ROLLBACK;
```

Find the key in the INSERT's output and the matching condition in the UPDATE. In the task, you
complete those two choices. One modifying-CTE statement is atomic even with autocommit ON; it
can also be part of a larger transaction. Grouping writes does not by itself protect a concurrent
cross-row decision. Communicate changes through RETURNING, without assuming sibling write order.

## 4. Lock an Existing Row

<!-- example: locking_syntax -->

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
CREATE TEMP TABLE guide_devices (device_id integer PRIMARY KEY, label text);
INSERT INTO guide_devices VALUES (9,'scanner');
SELECT device_id FROM guide_devices WHERE device_id=9 FOR UPDATE;
ROLLBACK;
```

This teaches syntax only: temporary data is private to one connection. The workshop task uses
shared tables. Choose the existing row on which competing writers coordinate, and hold its lock
until the whole operation ends. At Read Committed, perform the new count in its own selection
**after** lock acquisition. Do not combine that lock and count inside a single CTE.

## 5. Specify Isolation and Retry a Complete Decision

<!-- example: isolation_syntax -->

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SHOW transaction_isolation;
SELECT 1 AS first_data_query;
ROLLBACK;
```

Read Committed gives ordinary SELECT statements fresh committed views. Repeatable Read establishes
its stable data view at the first relevant query, not BEGIN alone. Stable reads do not protect every
cross-row rule. Serializable can reject an overlapping attempt: clear it, begin anew, repeat its
reads and decide again. P14's new count determines whether its supplied UPDATE may run.

<!-- rumdl-disable MD013 -->

| Outcome | What to Do |
| --- | --- |
| Statement is waiting | Leave it running, switch to the other connection and follow the numbered handoff |
| Serialization failure (`40001`) | Save the original error, ROLLBACK, then start a full fresh attempt |
| Ordinary no-seat/remain-on-duty decision | Skip the prohibited write and finish the transaction normally |
| Other error | Save it, ROLLBACK an explicit failed transaction, check the step/schema or ask for help |

<!-- rumdl-enable MD013 -->

In P14-2, if B2 errors, skip B3. If B2 succeeds, attempt B3. Do not replace the original error
with a later “transaction is aborted” message. In terminal psql, `\set VERBOSITY verbose` can
show SQLSTATE. Exact wording/location may vary. One controlled manual retry is required, not a loop.

## Save and Resume

Save the repaired SQL and the task's small result/explanation under `work/`. A legible result grid,
brief copied output or a small read table is enough. No per-step export inventory or observer capture
is required. Label supplied traces as supplied. Before pausing, finish or ROLLBACK open transactions;
resume from only that task's reset. In pgAdmin save SQL to your host `work/` folder. Container psql
cannot write to its read-only `/work`; use a local editor or copy any optional `/tmp` capture to host.

[Optional reference](practices-13-14-optional.md) contains CTE snapshot/empty/unused-output examples,
optional admission/staffing experiments and wait diagnostics. These are not extra core tasks.
Primary references: [RETURNING](https://www.postgresql.org/docs/18/dml-returning.html),
[modifying CTEs](https://www.postgresql.org/docs/18/queries-with.html#QUERIES-WITH-MODIFYING),
[isolation](https://www.postgresql.org/docs/18/transaction-iso.html), and
[complete retry](https://www.postgresql.org/docs/18/mvcc-serialization-failure-handling.html).
