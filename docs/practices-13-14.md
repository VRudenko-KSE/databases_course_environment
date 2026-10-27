# Practices 13–14: Write and Explain Transaction Repairs

**Practice 13:** three SQL repair exercises. **Practice 14:** two SQL labs and one short deadlock
ordering task. Work individually and resume independently. Short failure traces are supplied;
you do not need to reproduce every failure. Keep the last twenty minutes of each session for
assignment consultation. No separate worksheet or third connection is required.

Open the task file linked below and the [short SQL guide](practices-13-14-sql-guide.md).
Each task has its own starter with concrete numbered A/B blocks.
Copy one block's SQL into its named connection, use your editor's Toggle Comment command to remove
its leading `--`, fill its TODOs and execute only that block. Complete the repair decisions yourself.
Never run a completed starter as one script.

For each task save your completed SQL, **one compact observation and one short explanation** as
specified below. Use your own files under `work/`; no per-step export collection or wait screenshot.

## Prepare Only the Core Fixtures

Use the existing PostgreSQL 18 course environment. Start with `docker compose up -d --wait` from
its directory. New empty-volume installations load the fixtures automatically. Existing installations
need only a missing schema's migration; the only addition to the previous P13/P14 package is migration 88.

<!-- rumdl-disable MD013 -->

| Exercise | Schema | Migration | Starting Check | Reset |
| --- | --- | --- | --- | --- |
| P13-1 | `p13_atomicity` | [80](../sql/migrations/80-p13-atomicity.sql) | [Ready](../sql/mini-labs/p13_atomicity-ready.sql) | [Reset](../sql/mini-labs/p13_atomicity-reset.sql) |
| P13-2 | `p13_cte` | [88](../sql/migrations/88-p13-cte.sql) | [Ready](../sql/mini-labs/p13_cte-ready.sql) | [Reset](../sql/mini-labs/p13_cte-reset.sql) |
| P13-3 | `p13_locking` | [83](../sql/migrations/83-p13-locking.sql) | [Ready](../sql/mini-labs/p13_locking-ready.sql) | [Reset](../sql/mini-labs/p13_locking-reset.sql) |
| P14-1 | `p14_visibility` | [84](../sql/migrations/84-p14-visibility.sql) | [Ready](../sql/mini-labs/p14_visibility-ready.sql) | [Reset](../sql/mini-labs/p14_visibility-reset.sql) |
| P14-2 | `p14_serializable` | [86](../sql/migrations/86-p14-serializable.sql) | [Ready](../sql/mini-labs/p14_serializable-ready.sql) | [Reset](../sql/mini-labs/p14_serializable-reset.sql) |

<!-- rumdl-enable MD013 -->

Check a schema before installing, for example `SELECT to_regnamespace('p13_cte');`. If NULL, open
its migration in your SQL client and run the whole file, or use this terminal command:

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university   -f /course/sql/migrations/88-p13-cte.sql
```

Do not rerun a migration over an installed schema or delete the course volume. Ready/Reset files
are ordinary SQL: open and run the appropriate whole file in the GUI. Terminal psql users can
use, for example, `\i /course/sql/mini-labs/p13_cte-ready.sql`. Ready checks the starting state,
not your repair: changed rows after a task are expected. A partially installed schema needs TA help.

Open two independent connections A/B to the same database, with autocommit ON outside explicit
transactions. Run `SELECT current_database(),pg_backend_pid();` in each: the PIDs must differ.
P13-1 and P13-2 use A only. Each learner needs their own local instance or TA-provisioned database;
separate task schemas do not isolate learners sharing one database.

## Practice 13

Suggested route: 5 minutes setup; 12 atomicity; 12 CTE; 6 supplied traces; 20 locking; 5 buffer/exit.
These are pilot allocations, not measured completion times.

### P13-1 — Repair the Lending Boundary

Starter: [01-atomicity.sql](../work/practice-13/01-atomicity.sql).

In `p13_atomicity`, copy 1301 is available and there are no loans. A lending operation must both
insert its current loan and mark the copy loaned. Supplied failure: an autocommitted loan INSERT,
followed by an error before the copy update, leaves one loan and an available copy.

**Your work:** in the five `loan_A1`–`loan_A5` blocks, add the beginning, undo and successful ending
of an atomic unit. Both writes and their RETURNING lists are already supplied.

Run **A1 → A2 → A3 → A4 → A5**. A2's division-by-zero is a deliberate teaching fault; execute it
separately. A3 should undo that attempt and show the rows. A4 completes a successful operation.
Do not reset between these two attempts: a correct rollback restores the starting state.

**Save:** the rows after undo and after success. Explain why A1's returned loan row did not prove
that the lending operation committed. If your attempt leaves partial data, save the observation,
ROLLBACK, use this task's Reset file and repair your boundary before continuing.

### P13-2 — Connect Two Writes With RETURNING

Starter: [02-modifying-cte.sql](../work/practice-13/02-modifying-cte.sql).

Start independently in `p13_cte`: copy 1301 is available, no loans. It has the same tiny table shape
as Task 1 but shares no rows or state with it. A data-modifying CTE inserts a loan; the main UPDATE
marks the corresponding copy loaned.

**Your work:** complete only two gaps in `cte_A1`: the INSERT's returned linking key and the
UPDATE's matching condition. The DML bodies, values and final output columns are supplied.
Run **A1 → A2** with autocommit ON and no existing transaction.

**Save:** the returned copy row and one sentence explaining how the key connects the two writes.
You do not need a second error variant or CTE snapshot experiment.

### Short Supplied Comparisons — No Replay Required

- **Printer counter:** starts at 10. A and B both read 10; A writes literal 11 and commits;
  B writes its old literal 11 and commits. One increment is lost. Complete the one
  arithmetic expression below and explain where it is evaluated. This is SQL editing only; no counter fixture is needed.
- **Workshop race:** capacity 1, no registrations. A and B both read count 0. A inserts L-A and
  commits; B inserts L-B from its earlier decision and commits. Final count is 2, with distinct
  primary-key pairs. Identify the stale assumption and explain why this is not an overwritten row.

```sql
UPDATE printers SET requests_seen=/* TODO COUNTER_EXPRESSION */
WHERE printer_id=1302 RETURNING printer_id,requests_seen;
```

Use these comparisons to motivate the next repair; do not set up additional connections or resets.

### P13-3 — Repair Workshop Admission

Starter: [03-locking.sql](../work/practice-13/03-locking.sql).

In independent `p13_locking`, workshop 1304 has capacity 1 and no registrations. The tables are
`workshops(workshop_id,capacity)` and `registrations(workshop_id,learner_code)`. Rule: count must
not exceed capacity. Both competing workflows must coordinate on the same existing row.

**Your work:** choose the coordination table and locking clause in A1/B1. The counts, INSERTs,
RETURNING lists and COMMITs are supplied. In A3/B3 keep the INSERT only if the **new** count is
below capacity; otherwise comment it out. Always finish the transaction.

Seven selections: **A1 → B1 (leave waiting) → A2 → A3 → B2 → B3 → A4**.
Switch to A while B1 waits. Run B2 only after B1 finishes; B2 must be a new selection after lock
acquisition. Keep the provided Read Committed declarations. A third observer is unnecessary.

**Save:** A's and B's admission counts and the final registrations. Explain why B's count comes
after its wait, and which other admission/capacity-change writers must follow the same protocol.
Exit: why is locking an empty set of registrations different from locking the shared parent?

Minutes 60–80: A2 closing/readiness consultation. No early A3 opening is implied.

## Practice 14

Suggested route: 4 minutes recall/reconnect; 12 visibility; 6 supplied staffing trace;
22 Serializable/retry; 10 deadlock reasoning; 6 buffer/exit. Timing still needs a novice pilot.

### P14-1 — Compare Two Read Views

Starter: [01-visibility.sql](../work/practice-14/01-visibility.sql).

`p14_visibility.rooms` contains room 1401 at capacity 30. In `view_A1`, select Read Committed
first. Predict A's second read, then run **A1 → B1 → A2 → A3**. B1 changes capacity to 40 in one
autocommitted statement while A remains open.

Reset only this schema once. Repeat the four blocks at Repeatable Read with identical order.
A's first SELECT must precede B's change; it establishes the relevant stable snapshot.

**Save:** first/second/fresh-read values for each mode and one explanation. A stable read view
and protection of an admission rule are different requirements.

### Supplied Staffing Failure — No Replay Required

At Repeatable Read, I-A and I-B both start on duty. Each transaction counts 2 before either writes.
A takes I-A off duty and commits. B's stable view still counts 2; it takes I-B off duty and commits.
A fresh count is 0: the rule “at least one remains” failed, although the writes changed different rows.
Use this trace to explain why stable reads alone were insufficient.

### P14-2 — Repair the Staffing Decision and Retry It

Starter: [02-serializable.sql](../work/practice-14/02-serializable.sql).

Start independently in `p14_serializable`, exam 1403, both staff on duty. Ordinary reads and UPDATEs
are supplied in the `serial_` blocks. The rule permits removing one's own staff member only when
another remains.

**Your work:** choose the stronger isolation mode and complete the rejected-attempt cleanup and
new retry boundaries. In B6 decide from B5's fresh count whether to keep or comment out the UPDATE.
Do not copy the earlier count or retry just the failed write.

At most nine selections: **A1 → B1 → A2 → B2 → (B3 only if B2 succeeded) → B4 → B5 → B6 → A3**.
Both initial reads must finish before A2. If B2 errors, save that original error and skip B3.
If B2 succeeds, attempt B3 and save its actual serialization error. Then clean up in B4 and start
the full new attempt in B5. Do not add a parent lock to this isolation comparison.

**Save:** original error, retry count and final staff rows. Explain why the new business decision
may be “remain on duty” even though the original attempt tried to leave. This is one controlled
manual retry; no application or retry loop is required.

### P14-3 — Repair a Deadlock Order

Starter: [03-deadlock-order.sql](../work/practice-14/03-deadlock-order.sql).

**Reasoning/SQL editing only; no engine replay required.** A holds resource 1404 and requests 1405;
B holds 1405 and requests 1404. Both are inside operations that need both resources.

Mark the two wait arrows. The starter supplies the two UPDATE statements: write a common resource
order for both workflows, then predict the remaining ordinary wait. Explain which edge of the
original cycle that order prevents. No deadlock fixture is needed for this reasoning task.

Minutes 60–80: A3 setup/first-diagnosis consultation at its scheduled launch, using the current brief.
These practices do not change assignment requirements. Reuse the deadlock explanation at the next opening.

## Pause, Recover or Explore Further

Save your SQL/results and finish or ROLLBACK any open transaction before pausing. Resume by resetting
only the relevant task, never by relying on a transaction surviving a break. Ready/Reset files refuse
unexpected structure/dependencies or held locks. After a refusal, ROLLBACK, inspect the cause and ask
for help if needed. Do not delete saved objects or reset the whole Docker volume to make a check pass.

[Optional reference and replays](practices-13-14-optional.md) cover extra CTE behavior, counter/rota
transfers, optional admission/staffing experiments and a third-connection observer. None is required for core
completion or compulsory break homework. GUI controls and novice timing still need actual rehearsal.
