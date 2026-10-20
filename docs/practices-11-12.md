# Practices 11–12: SQL Investigations and Indexes

Each session has **four core tasks and one optional task**. All tasks are **individual**: save your own SQL,
results and explanations. Work online or in person, and pause and resume independently; a partner and
continuous live attendance are not required. Use the [SQL guide](practices-11-12-sql-guide.md) for syntax examples.

Minute marks are suggested live-session pacing. Guided SQL occupies minutes 0–60; minutes 60–80 are reserved
for optional Assignment 2 consultation. You may complete the work independently, following any published
submission deadlines and the assignment's existing requirements.

Practice 11 connects a short storage-model demonstration to requirements, booking intervals and pagination.
Practice 12 turns event history into gaps, sessions and activity streaks, then investigates CTE execution.
Each SQL task combines a correct report with a measured index experiment.

## Prepare the Existing Course Environment

Use PostgreSQL 18 and the existing Docker environment. New empty-volume installations load
[migration 70](../sql/migrations/70-practices-11-12.sql) and
[the edge-case upgrade 71](../sql/migrations/71-practices-11-12-edge-cases.sql) automatically.
For an existing installation,
update the package files, start the services, and open container `psql` from the `course-environment` directory:

```sh
docker compose up -d --wait
docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university
```

Check whether the fixture is already installed:

```sql
SELECT to_regclass('advanced_lab.portal_events');
```

Only if the result is NULL, exit with `\q` and apply the migration once from your terminal:

<!-- rumdl-disable MD013 -->

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/migrations/70-practices-11-12.sql
```

<!-- rumdl-enable MD013 -->

After that check, exit interactive psql with `\q` if it is still open. Apply upgrade 71 and check readiness
from your terminal **even if the fixture already existed**. Matching table counts alone cannot identify
the current edge cases. Reapplying 71 to its current rows is safe.

<!-- rumdl-disable MD013 -->

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/migrations/71-practices-11-12-edge-cases.sql
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/practices-11-12-ready.sql
```

<!-- rumdl-enable MD013 -->

Expect `Practice 11-12 data ready (migration 71)`. Upgrade 71 changes three supplied background rows and
preserves other work and indexes. If a target row was edited or removed, it refuses the complete upgrade.
Save your work and ask your TA to inspect the target; use the scoped checkpoint only after saving edits.
If the refusal occurs inside interactive psql, run `ROLLBACK;` before continuing.

Restarting Docker does not replay migrations. Keep the existing volume; adding this fixture does not require
`docker compose down -v`. If migration 70 fails or the schema is partly installed, save your work and use the
scoped checkpoint below with your TA. Custom database usernames/names require matching command flags.

Reopen `psql`, check the fixture, and refresh the schemas in your SQL client:

```sql
SET TIME ZONE 'UTC';
SELECT COUNT(*) AS students FROM advanced_lab.students;
SELECT COUNT(*) AS bookings FROM advanced_lab.bookings;
SELECT COUNT(*) AS portal_events FROM advanced_lab.portal_events;
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'advanced_lab'
ORDER BY tablename, indexname;
```

Expect 10,000 students, 200,000 bookings and 240,000 portal events. The complete fixture also contains
10 programmes, 30 courses, 27 requirements, 100,000 attempts and 200 rooms.
The initial indexes enforce the primary and unique constraints; added experimental indexes will appear
after you create them.

Open the [Practice 11 starter](../work/practice-11.sql) or
[Practice 12 starter](../work/practice-12.sql). Run `SET TIME ZONE 'UTC';` in every SQL connection.
Use the fixed 2026 dates given below, even when taking the course later.

The starters include commented partial outlines for P11-4 and P12-4. Complete the missing reasoning
before running them. Prepare these files whenever you begin
the practice, online or in person; they add no separate preparation assignment.

## Dataset and Report Meaning

The independent `advanced_lab` schema contains fictional, deterministic records. Background data provides
enough work to investigate access paths; small edge cases expose incorrect query logic.

<!-- rumdl-disable MD013 -->

| Table | One Row Means | Columns |
| --- | --- | --- |
| `programmes` | One study programme | `programme_id, programme_name` |
| `students` | One student in a programme | `student_id, full_name, programme_id` |
| `courses` | One catalogue course | `course_id, title` |
| `requirements` | One course required by one programme | `programme_id, course_id` |
| `attempts` | One student's attempt at a course | `attempt_id, student_id, course_id, grade` |
| `rooms` | One bookable room | `room_id, room_name, capacity` |
| `bookings` | One reserved interval for a room | `booking_id, room_id, starts_at, ends_at` |
| `portal_events` | One observed portal action | `event_id, student_id, occurred_at, event_type` |

<!-- rumdl-enable MD013 -->

Primary keys and the composite requirements key prevent duplicate identities. Attempts can repeat a
student/course pair. A grade is 0–100 or NULL; NULL means no recorded grade and never counts as a pass.
A pass in **any** attempt satisfies that course; a later failure does not erase it. A pass in a course outside
the programme's requirements does not satisfy a requirement. Programme 10 deliberately has no requirements.

Bookings have non-NULL timestamps with `starts_at < ends_at`. Their intervals are half-open:
`[starts_at, ends_at)`. One booking ending exactly when another starts does not conflict. The booking fixture
is a frozen snapshot for pagination; do not insert, update or delete rows during the comparison.
Events also have non-NULL timestamps, and several can share the same timestamp. The event ID breaks ties.

## Experiment Protocol and Saved Evidence

For each task, write **one main SELECT**, with CTEs where useful. The named exceptions are P11-1's programme
parameter check, P11-4's OFFSET/keyset variants, and P12-4's three CTE variants. Setup commands, checks, index
DDL and plan captures are separate from the report. Both averages in optional P12-5 belong in one result.

1. Save earlier evidence and restore the supplied index baseline. Constraint indexes remain in place:
   baseline means **without your added candidate**, not an index-free database.
2. Execute your SELECT normally. Check the specified output columns, row grain, boundaries, NULLs,
   duplicates, ties and final ordering. Record a prediction about which work an index might reduce.
3. Run the SELECT once as a read warm-up, then capture `EXPLAIN (ANALYZE, BUFFERS)` for the baseline.
4. Choose and justify a candidate index, create it, and run `ANALYZE` on its table.
5. Repeat the same warm-up and plan capture with the **identical SELECT and parameters**. Verify that all
   result rows, values and ordering are unchanged.
6. Save the SELECT, parameters, candidate definition, actual results, both plans and a short explanation.
   Calculate indexed minus baseline execution time in milliseconds and compare buffers at the same named node
   or at the complete-query level. Negative time difference means the indexed run was faster.

Test candidates independently: reset to baseline before installing a competing design. For a query-rewrite
comparison, keep the indexes fixed and prove result equality; changing SQL and indexes together obscures the cause.
P11-4 and P12-4 say exactly which variants to compare. Do not force PostgreSQL to choose a particular scan.
An unchanged plan, slower run or negligible improvement is a valid result when explained.

<!-- rumdl-disable MD013 -->

| Query / Parameters | Configuration | Main Access Path | Rows / Loops | Shared Hits / Reads | Execution ms | Index Bytes | Explanation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Task and variant | baseline / candidate | Observed node | Named node's values | Named node's values | Measured value | Measured value | Work reduced and work remaining |

<!-- rumdl-enable MD013 -->

`EXPLAIN ANALYZE` executes the query but does not display its result rows. Capture actual results separately.
Save evidence under `work/` with task and configuration labels. Keep predictions when observations disagree.
Use the [complete-result checks and export procedure](practices-11-12-sql-guide.md#12-check-complete-results-and-save-evidence)
to compare all values, duplicate counts and final order; temporary snapshots and comparisons stay outside timing.
Use the [P9/P10 plan guide](practices-09-10-sql-guide.md) to interpret filters, loops, buffers and remaining work.

## Practice 11: Requirements, Intervals and Pages

By the end of the workshop, you should be able to distinguish existence from counting, express interval
overlap precisely, and explain how ordering and the number of skipped rows affect a page request.

### Minutes 0–10: Observe the LSM Model

Explore the [LSM simulator](https://saiprakash.in/lsm) independently or follow the instructor's brief
walkthrough when available. Use the Lecture 6 examples if the simulator is unavailable.
Use manual operations and small thresholds to observe a value entering memory, a flush, a newer value for the
same key, and compaction. For a missing-key lookup, inspect the Bloom-filter read trace.
Record one observation about where the newest value is found and one about work avoided or repeated during reads.

The simulator's files, counters and timing belong to its illustrative model. They are not PostgreSQL
measurements and do not predict the query plans below. No storage-engine implementation is required.
If you use a supplied state trace, label it as supplied evidence. SQL tasks do not depend on attending
the demonstration live.
Briefly reuse the P10 exit question: which query justified an index, and what did that index cost?

### P11-1 — Any, None and Every Requirement

**Core, minutes 10–22.** Start with all students in programme 1. Return
`student_id, full_name, has_any_pass, has_all_pass`, ordered by `student_id`.
The two flag columns must be non-NULL Booleans.

- `has_any_pass` is true when at least one course required by that student's programme has an attempt
  with `grade >= 60`.
- `has_all_pass` is true when every required course has at least one such passing attempt.
- Explain “none” as `NOT has_any_pass`; keep the requested four-column report rather than adding a third flag.

Use correlated existence tests: first decide whether a qualifying row exists, then express “every” by looking
for a missing required course. Multiple passes for one course cannot compensate for another course's absence.
Check an ungraded attempt, repeated attempts, a missing course and a student with no qualifying passes.
Rerun the same report for programme 10. Explain why its empty requirement set gives false for “any” and true
for “every”; the statement is about requirements, not an award of a real qualification.
Students 1–6 are the small programme-1 cases: inspect their attempts and the programme's requirements
to explain each flag rather than relying on the overall result count. Student 1 has both passing and failing
attempts for the same required course; student 6 has a pass outside the required set. Attempt IDs identify
rows; they do not define a chronology or a rule to select the latest attempt.

Choose an index for repeated attempts lookups and justify the key order using the correlation columns.
Measure the programme-1 query before and after adding it. Keep the programme-10 rerun as a semantic check;
it does not require another measured plan pair. Save unchanged flags, paired plans and your explanation.

### P11-2 — Find Conflicting Booking Pairs

**Core, minutes 22–35.** Write a self-join of bookings for room 1. Both bookings must overlap
`[2026-10-20 09:00:00+00, 2026-10-20 12:00:00+00)`, and they must overlap one another.
Return `room_id, booking_a, booking_b, overlap_start, overlap_end`, ordered by
`room_id, booking_a, booking_b`.

Return each unordered pair once by requiring `booking_a < booking_b`. Never pair a booking with itself.
`overlap_start` is the later booking start; `overlap_end` is the earlier booking end. These describe the
bookings' full intersection, without clipping it to the reporting interval. Express overlap with strict
inequalities so touching endpoints do not count.

Trace one genuine conflict, one adjacent pair and one excluded boundary booking. Choose and justify an index
for the room restriction and one interval bound. Measure this identical report before and after creating it.
Identify any other bound still checked as a filter; a correct index can leave substantial qualification work.
Bookings 1–4 provide a small trace: compare pairs `(1,2)` and `(3,4)` against the strict overlap definition.

### P11-3 — Find an Available Room

**Core, minutes 35–47.** Find rooms with capacity at least 30 and no booking overlapping
`[2026-10-20 10:00:00+00, 2026-10-20 11:00:00+00)`. Return
`room_id, room_name, capacity`, ordered by `room_id`.

Start from rooms and use a correlated `NOT EXISTS` test for blocking bookings. Keep qualifying rooms with no
bookings. A booking ending at 10:00 or beginning at 11:00 leaves this requested interval available.
Check a never-booked room, a too-small room and a room whose booking touches an endpoint.
Room 200 is a never-booked room with capacity 40; use it to check that the query starts from rooms.

Use the P11-2 experience to choose an index for the correlated room lookup and a time bound.
Capture the baseline and indexed plans for this availability query. In your explanation, predict what might
change if the candidate used the other time bound. The instructor will compare the two designs during feedback;
your required evidence is one independently measured candidate.

### P11-4 — Retrieve the Same Deep Page Two Ways

**Core, minutes 47–60.** Return `booking_id, room_id, starts_at, ends_at`, ordered by
`starts_at DESC, booking_id DESC`, limited to 20 rows. Write two named equivalent variants:

1. **OFFSET:** skip 100,000 rows in that order, then return 20.
2. **Keyset:** use the supplied timestamp/ID cursor for the immediately preceding row and return the next 20.
   Compare the ordered pair using a strict bound consistent with descending order. Keep the ID tie-breaker.

Obtain the matching cursor using the helper below. Cursor acquisition is setup and is excluded from the timed
keyset SELECT; do not embed the deep OFFSET lookup inside that SELECT. Keep the supplied timestamp precision
and ID. The frozen fixture makes both pages comparable; save and compare all 20 rows in order.

With baseline indexes fixed, measure both variants. Choose an index matching the page's ordering, create it,
and measure both unchanged variants again. This gives each variant its own before/after pair, plus an
OFFSET-versus-keyset comparison under each fixed index configuration. Explain skipped work, filtering and
sorting observed in the plans. A cursor locates a continuation point; it does not provide an arbitrary page
number without prior setup.

Individual exit: **Why do adjacent bookings not conflict, and what index condition can narrow the overlap search?**

### P11-5 — Case-Insensitive Exact Matching

**Optional.** Return `student_id, full_name` for students satisfying
`lower(full_name) = 'olena bondar'`, ordered by `student_id`. Keep this exact predicate across all measurements.
Design an ordinary name index and an expression index, and test each independently from the same baseline.
Explain whether the indexed expression matches the query expression; do not replace the equality with a
substring search. Save both comparisons and index sizes.

## Practice 12: Ordered Events and CTEs

By the end of the workshop, you should be able to preserve row order through several calculation stages,
distinguish observations from calendar days, and explain the measured effect of CTE materialization.
Begin from the constraint-only index baseline; keep Practice 11 evidence.

For P12-1 and P12-2 the reporting week is
`[2026-03-01 00:00:00+00, 2026-03-08 00:00:00+00)`.
For P12-3, P12-4's March count and P12-5, March is
`[2026-03-01 00:00:00+00, 2026-04-01 00:00:00+00)`.
All event types count. Apply these report bounds before the windows unless the task explicitly asks for
all-history information.

### P12-1 — Measure Event Gaps

**Core, minutes 0–15.** For student 42 in the reporting week, return
`event_id, occurred_at, previous_at, gap_minutes, starts_session`, ordered by `occurred_at, event_id`.

Calculate the previous timestamp with `LAG`, using timestamp then event ID as the total order. In the next
query stage calculate the gap in minutes and a Boolean start flag. The first event has NULL `previous_at`
and NULL `gap_minutes`, and starts a session. Every later event starts a session only when its gap is
**strictly greater than 30 minutes**. Exactly 30 minutes stays in the same session; equal timestamps have gap zero.
Keep fractional minutes if present.

Event 25 follows the tied 01:01 events by 30 minutes 30 seconds. Check that its reported gap keeps the
fractional minute and that the strict session-boundary rule is applied to the complete interval.

The report resets at March 1: an event just before the report boundary cannot be the first row's predecessor.
Choose and justify an index for the student/time restriction and ordered history. Measure the identical report
before and after adding it. Save the edge checks and explain any remaining sort or window work.

### P12-2 — Build Session Summaries

**Core, minutes 15–30.** For students 1–100 inclusive in the same reporting week, return
`student_id, session_no, session_start, session_end, event_count, duration_minutes`,
ordered by `student_id, session_no`.

Use these stages in one statement: restrict events; calculate `LAG` within each student; mark the first event
or a gap greater than 30 minutes; calculate a running sum of integer start flags; then aggregate each session.
Use the same `(occurred_at, event_id)` ordering throughout and an explicit
`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` frame for the sum.

Extend the predecessor/flag stages you wrote for P12-1. Add the student partition to each window before
adding numbering and aggregation. Reuse the calculation structure, then capture a fresh plan pair for
this complete session report.

Session numbers start at 1 separately for each student. Start and end are the session's earliest/latest
event timestamps; duration is their difference in minutes. A single-event session has duration zero.
Count all events, including simultaneous events. Students without events contribute no session row.
Reconcile the sum of session event counts with eligible input events.

Reset indexes, then test one justified candidate against the baseline with the identical session query.
Compare access, ordering, window and aggregation work. The short result is not evidence that few events were read.

### P12-3 — Find Consecutive Active-Day Streaks

**Core, minutes 30–45.** For students 1–100 inclusive in March, return all streaks of at least three
consecutive UTC dates as `student_id, streak_start, streak_end, active_days`,
ordered by `student_id, streak_start`.

First deduplicate each student's active UTC dates. Then detect breaks between dates, label each consecutive
group, and aggregate it. Filter groups to at least three dates after calculating their lengths.
`streak_start` and `streak_end` are dates, and `active_days` counts distinct active dates.
A student may have several result rows. Multiple events on one day cannot extend a streak, and an inactive
day breaks it. The report boundary truncates a streak: do not include February or April activity.

Use one main SELECT with CTE stages; either the gap-flag method or a justified date/row-number grouping is valid.
Choose a candidate for the input restriction and measure the same query before and after adding it.
Check duplicate-day and missing-day cases, then distinguish input access from deduplication and grouping work.

### P12-4 — Explain CTE Materialization

**Core, minutes 45–60.** For students 42 and 43, return
`student_id, march_events, latest_event_at`, ordered by `student_id`. Retain both students even if they have
no eligible events.

Write a CTE that reads `student_id, occurred_at` from the complete `portal_events` history. From an outer
student row, use **two correlated scalar subqueries** referring to that CTE: one counts the student's March
events; the other finds the student's latest timestamp across all history. Do not prefilter the common
source to March, because the latest event can fall outside March.

Compare three named versions differing only in the CTE declaration: default `AS (...)`,
`AS MATERIALIZED (...)`, and `AS NOT MATERIALIZED (...)`. Keep baseline indexes fixed for these three
measurements. Save equal results, including zero for an empty count and NULL for a missing latest timestamp.
Inspect CTE scans, base-table access, filters and repeated work; do not infer performance from syntax alone.

Next keep the `NOT MATERIALIZED` query fixed. Choose an index for its correlated predicates and compare
that exact version before/after the candidate. Its baseline plan can be reused from the first comparison.
This separates the effect of the rewrite from the effect of adding an index. Explain a situation where
sharing an expensive calculation could make materialization helpful.

Individual exit: **Why does filtering or indexing input not remove all window/CTE work, and which plan observation
supports your explanation?**

### P12-5 — Seven Observations or Seven Calendar Days

**Optional.** For student 42 in March, aggregate events to observed UTC dates and return
`activity_date, event_count, seven_observation_average, seven_calendar_day_average`, ordered by `activity_date`.

Calculate both averages in one SELECT over the daily counts. For the first use `ROWS BETWEEN 6 PRECEDING
AND CURRENT ROW`; for the second order by the date converted to a midnight timestamp and use
`RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW`. This includes the current date and the preceding
six calendar dates. Do not generate missing dates or turn them into zero counts.

The first average uses up to seven observed rows; the second uses observed rows in that calendar interval.
Compare their contributors after an inactive day. Choose an input-access index and measure the identical
two-average query before and after it. Explain why an index cannot change either average's meaning.

## Resets, Cursor Setup and Size Checks

Save your SQL and evidence first. In container `psql`, use the relevant command below.
These are `psql` commands; they do not run in pgAdmin's Query Tool.

```text
-- Remove experimental indexes in advanced_lab; keep rows and constraint indexes.
\i /course/sql/practices-11-12-reset-indexes.sql

-- Inspect definitions and individual index/table/total sizes.
\i /course/sql/practices-11-12-sizes.sql

-- Obtain the cursor immediately before the OFFSET 100000 page.
\i /course/sql/practices-11-12-cursor.sql

-- Full P11/P12 recovery: discard advanced_lab edits and recreate its seed.
\i /course/sql/practices-11-12-checkpoint.sql
```

The checkpoint rebuilds `advanced_lab` and preserves earlier practice schemas and host work files.
It refuses to proceed if extra objects or external dependencies, such as a saved view, prevent a scoped reset.
If this happens in interactive psql, run `ROLLBACK;` to leave the failed transaction.
Ask your TA to help save and remove those dependencies before retrying.
The index reset preserves constraint indexes and removes added indexes throughout `advanced_lab`.
On a shared database, the TA coordinates DDL and resets. Independent measurements require independent
database instances or instructor-assigned isolated copies.

## Timing and Handoff

Use this sequence as a pacing guide. You can pause, resume and complete tasks independently; the live
consultation period is optional. Save your progress and follow any published submission deadlines.

<!-- rumdl-disable MD013 -->

| Practice | Minutes | Activity | Checkpoint |
| --- | --- | --- | --- |
| 11 | 0–10 | Instructor LSM demonstration and P10 exit recall | One version/flush observation and one read-trace observation |
| 11 | 10–22 | P11-1: requirements | Correct flags, empty-set explanation and plan pair |
| 11 | 22–35 | P11-2: conflicts | Unique pairs, endpoint check and plan pair |
| 11 | 35–47 | P11-3: availability | Empty-room/boundary check and plan pair |
| 11 | 47–60 | P11-4: pagination and exit | Equal pages, fixed-query plan pairs and fixed-index rewrite comparison |
| 12 | 0–15 | P12-1: gaps | First-row/30-minute/tie checks and plan pair |
| 12 | 15–30 | P12-2: sessions | Counts reconciled, staged windows and plan pair |
| 12 | 30–45 | P12-3: streaks | Distinct-date checks and plan pair |
| 12 | 45–60 | P12-4: CTEs and exit | Equal variants, separate rewrite/index evidence |
| Both | 60–80 | Assignment 2 studio | Individual feedback and a recorded next action |

<!-- rumdl-enable MD013 -->

Each SQL block combines syntax examples, individual work and result comparison. Use the small guide
examples before adapting the new syntax. Ask the TA for a hint, a partial query or a saved checkpoint
when blocked, then resume independently. Label supplied results/plans and record what still needs your own run.
These timings are a guided teaching plan; they are not a measured novice completion guarantee.

Optional tasks are for early finishers or later study and never displace Assignment 2 studio. They are not
extra core requirements or automatic bonus credit. No work is required during the break.
In the studio, apply a correctness check and a controlled plan comparison to your own Assignment 2 work;
keep practice files separate from the assignment submission and follow the assignment's existing requirements.
