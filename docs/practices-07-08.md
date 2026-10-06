# Practices 7–8 — Practical PostgreSQL Reporting and Window Functions

Run every exercise in PostgreSQL through pgAdmin, DBeaver, or PyCharm. Save **SQL, output, and a short
explanation** under `work/`. Each session has **eight tasks: four core and four optional extensions**.
Every task asks for one student-written query; reuse a previous CTE inside that query when useful.

Practice 7 builds daily activity and current-registration reports: four cycles of 10 minutes writing/running
and 5 minutes comparing a solution, followed by 20 minutes of Assignment 2 orientation.
Practice 8 uses **all 80 minutes for window functions**: four core cycles, then 20 minutes of application,
feedback, and an individual exit. Assignment 2 opens after Practice 8; its next studio is Practice 9.

Read the separate [SQL guide](practices-07-08-sql-guide.md) for explanations, runnable examples,
and documentation links for the new reporting and window-function topics.

## How to work and what to save

Open the SQL starter for the session in your chosen interface and write your solutions below its prompts.
Use the task ID, such as `P7-3` or `P8-7`, as a SQL comment before each query. Each solution is one query;
its CTEs belong to the same statement. Run the selected query while working, then save the complete file.
For P7, run the UTC setting in that same connection before selecting an individual query.

For every completed task, keep these three pieces of evidence under `work/`:

- **SQL:** the complete query, with meaningful output aliases and the requested final ordering.
- **Output:** the result grid or a CSV export, labelled with the task ID. Include column headers, row count
  and visible NULL values. For example, save P7-3's export as `work/P7-3.csv`.
- **Explanation:** a few sentences answering that task's prompts, using actual rows from your output.
  Put them in SQL comments or a separate notes file. For P7, record the report period/cutoff and time zone;
  for P8, record the input rows, partition, ordering and frame when they affect the calculation.

Predict one relevant boundary, tie, missing date or NULL case before running the query. Compare that
prediction with the result and record any correction. During the solution comparison, check row membership
and calculation rules as well as values; a plausible total alone does not establish that the report is correct.

## Prepare the fixture

Fresh volumes run all numbered migrations automatically. Existing volumes do not replay them.
With the updated course package, check which schemas needed by this pair are present:

```sql
SELECT to_regnamespace('reporting_lab') AS window_schema,
       to_regnamespace('activity_lab') AS activity_schema;
```

From the package directory, run the corresponding command **once for each missing schema**.
Skip migration 40 if reporting_lab exists; skip migration 50 if activity_lab exists.
If you already installed the previous P7–8 package, you normally need only migration 50.

<!-- rumdl-disable MD013 -->

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/migrations/40-practices-07-08-reporting.sql
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/migrations/50-practice-07-activity.sql
```

<!-- rumdl-enable MD013 -->

The course SQL directory is already mounted. Adding these fixtures does not require deleting the volume.
Run this readiness query in your SQL interface:

```sql
SELECT 'students' AS fixture, COUNT(*) AS records FROM activity_lab.students
UNION ALL
SELECT 'workshops', COUNT(*) FROM activity_lab.workshops
UNION ALL
SELECT 'registrations', COUNT(*) FROM activity_lab.registrations
UNION ALL
SELECT 'activity events', COUNT(*) FROM activity_lab.registration_events
UNION ALL
SELECT 'window results', COUNT(*) FROM reporting_lab.results
ORDER BY fixture;
```

Expect students 7, workshops 4, registrations 10, activity events 18, and window results 14.
All tasks are read-only. P8 starts independently from its unchanged fixture even if you missed P7.
The two labs contain fictional exercise data with their own identifiers; they do not change canonical
university enrolments. No work is required during the break.

For recovery only, this command replaces **all objects and edits in activity_lab and reporting_lab**:

<!-- rumdl-disable MD013 -->

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/practices-07-08-checkpoint.sql
```

<!-- rumdl-enable MD013 -->

Earlier practice schemas, storage_lab and host work files are preserved. Save experiments in the two
affected schemas before using the checkpoint.

If the schemas already exist but the counts differ, check that you opened the `university` database and
have the updated package. An earlier P7 fixture had nine registrations and seventeen events; restarting
Docker does not update that fixture. After saving any lab edits, the scoped checkpoint above restores the
current baseline. Rerunning migration 50 over an existing activity_lab schema will fail rather than upgrade it.
On the shared course instance, coordinate fixture recovery with the TA.

## Practice 7 tasks — Dates, Dashboards, and Latest State

Open [the starter](../work/practice-07.sql). Build reports for campus workshop registrations.
A registration can be cancelled and registered again. The event history records each status change;
a registration's latest event determines its state at the report cutoff.

| Table | One row means | Main columns |
|---|---|---|
| `activity_lab.students` | One fictional student | `student_id, full_name` |
| `activity_lab.workshops` | One workshop | `workshop_id, title` |
| `activity_lab.registrations` | One student/workshop association | `registration_id, student_id, workshop_id` |
| `activity_lab.registration_events` | One recorded status change | `event_id, registration_id, occurred_at, status` |

Event status is `registered` or `cancelled`. Events can share a timestamp; **the larger event_id is defined
as later when timestamps tie**. Registration IDs identify associations, rather than individual events.

Execute the starter's setting in the connection used for all P7 tasks:

```sql
SET TIME ZONE 'UTC';
SHOW TimeZone;
```

The fixture uses timestamp-with-time-zone values (`timestamptz`). UTC is the reporting time zone for this
workshop: date casts and weekly buckets use that session setting. Reapply it after reconnecting.
Use fixed report boundaries rather than today's date:

- September activity: at or after `TIMESTAMPTZ '2026-09-01 00:00:00+00'`, before October 1.
- End-of-September state: all events **before** `TIMESTAMPTZ '2026-10-01 00:00:00+00'`, including earlier history.
- First-week calendar: September 1–7, inclusive.

The three teaching ideas and outcomes are:

- **Reports need an explicit time scope.** Select the correct period and explain the boundary events.
- **A useful dashboard defines metrics and missing dates.** Build separate status counts and retain quiet days.
- **History and current state answer different questions.** Resolve the latest event before testing its status.

<!-- rumdl-disable MD013 -->

| Optional | Task | Execute | Explain and save |
|:---:|---|---|---|
| false | P7-1: Report September activity | Read activity_lab.registration_events and select September 2026 events using `occurred_at >= TIMESTAMPTZ '2026-09-01 00:00:00+00'` and an exclusive October 1 boundary. Return `event_id, registration_id, occurred_at, status`; keep individual events, including repeated registration IDs. Order by occurred_at, then event_id. Check events at the start, on the final day, and immediately outside the period. | State what one output row represents and save the row count. Identify an included September boundary event and excluded August/October events by ID and timestamp. Explain why a September 30 midnight endpoint loses later events that day, and why the half-open interval works without guessing the timestamp precision. |
| false | P7-2: Build daily metrics | Reuse P7-1's September predicate. Group events by `occurred_at::date` in the UTC connection and calculate separate `COUNT(*) FILTER` expressions for registered and cancelled statuses. Return `activity_date, registered_events, cancelled_events`, ordered by activity_date. Produce one row per date that has activity; do not create missing dates in this task. | Define both counts as recorded events, rather than people or active registrations. Trace a date containing both statuses and a date with only one status. Reconcile the sum of both columns with P7-1's row count. Explain how the session time zone determines the date cast and why the quiet day is absent from this result. |
| false | P7-3: Include quiet days | Build a daily-count CTE for the period from September 1 inclusive to September 8 exclusive. In a second CTE, use generate_series to construct all seven calendar dates September 1–7. Start the final query from that calendar, left join the counts and use COALESCE to display zero for each missing count. Return `activity_date, registered_events, cancelled_events` in date order. | Confirm that the result has one row for each of the seven requested dates and identify the quiet day. Trace how an unmatched calendar row becomes two zero counts. Explain why grouping events alone cannot create that row and why an inner join would remove it. Distinguish an observed zero-event day from a date outside the requested calendar. |
| false | P7-4: Recover current state | In a `latest` CTE, consider all events before October 1, including August history. Use DISTINCT ON (registration_id), with registration_id leading ORDER BY, then occurred_at descending and event_id descending. In the outer query retain status registered and join registrations for student/workshop IDs. Return `registration_id, student_id, workshop_id, event_id, occurred_at, status`, ordered by registration_id. | Trace one cancellation, one re-registration and the equal-timestamp pair; identify the event that determines each state. Find the active registration whose history is entirely in August and explain why a September lower bound would lose it. Explain why filtering registered status inside the CTE can resurrect a cancelled registration, and why the October event must not affect this snapshot. |
| true | P7-5: Students who have cancelled | Start from activity_lab.students. Use a correlated EXISTS subquery that joins that student's registrations to cancellation events before October 1; include earlier history and use student_id to connect the subquery to the outer student. Return `student_id, full_name` once per qualifying student, ordered by student_id. Do not require the student's current state to be cancelled. | Choose a student with more than one cancellation and show why the output still contains only one student row. Compare the meaning of EXISTS with an ordinary join that could repeat that student. Explain why a later re-registration does not erase the fact that a cancellation occurred, and why this report answers a different question from P7-4. |
| true | P7-6: Participant lists | Reuse P7-4's latest-state CTE and cutoff. Start from all workshops and left join registrations, their latest active events and students, retaining workshops with no active participants. Return `workshop_id, title, participant_count, participants`; count a non-NULL active registration key and build an alphabetically ordered name list with STRING_AGG. Keep an empty list NULL and order final rows by workshop_id. | Trace an active participant and a workshop with zero participants through the joins. Explain why COUNT(*) could count a placeholder row, and why students attached only to inactive registrations must not appear in the list. Distinguish aggregate name ordering from final workshop ordering. Explain why the comma-separated text is a display result while the stored relationships remain individual rows. |
| true | P7-7: Weekly reporting | Filter events to the September interval before grouping. Use `date_trunc('week', occurred_at)::date` as `week_start` in the UTC connection, then calculate registered and cancelled event counts with FILTER. Return `week_start, registered_events, cancelled_events`, ordered by week_start. Include weeks with activity; a complete zero-filled weekly calendar is outside this task. | Identify the first and last week labels and state which September dates those buckets can contain. Explain why the first label can be in August while no August event is counted. Describe the Monday week boundary, the partial first/last weeks and the time-zone setting. Reconcile weekly totals with P7-2's daily totals to check that bucketing did not change the report period. |
| true | P7-8: Define a safe ratio | Build a metrics CTE starting from every workshop. Left join registrations and September events, placing the event-period restriction in the join so empty workshops survive. Return registered/cancelled event counts, then calculate `ROUND(100.0 * cancelled_events / NULLIF(registered_events, 0), 1)` as `cancellation_event_ratio_pct`. Return `workshop_id, title, registered_events, cancelled_events, cancellation_event_ratio_pct`, ordered by workshop_id. | State the numerator, denominator and reporting period in words. Explain why 100.0 gives numeric division, why NULLIF avoids division by zero, and why an undefined ratio remains NULL rather than zero. Find a workshop with a 100% ratio that still has an active participant in P7-6. Explain why period event counts are not a cohort's cancellation percentage and can exceed 100% on other histories. |

<!-- rumdl-enable MD013 -->

The following small demonstrations provide new syntax without using your exercise data.

```sql
WITH demo(state) AS (VALUES ('open'), ('closed'), ('open'))
SELECT COUNT(*) FILTER (WHERE state = 'open') AS open_events
FROM demo;

SELECT DATE '2026-01-01' + day_offset AS day
FROM generate_series(0, 2) AS days(day_offset);

WITH demo(device, version, reading) AS (
    VALUES ('A', 1, 10), ('A', 2, 15), ('B', 1, 7)
)
SELECT DISTINCT ON (device) device, version, reading
FROM demo
ORDER BY device, version DESC;
```

DISTINCT ON keys must lead the ORDER BY expressions. Add the timestamp and event ID ordering to define
which row wins within each registration. A CTE lasts for one query; copy its definition when reusing it.

Optional syntax reminders: `WHERE EXISTS (SELECT 1 ...)`;
`STRING_AGG(name, ', ' ORDER BY name)`; `date_trunc('week', timestamp)`;
`ROUND(100.0 * numerator / NULLIF(denominator, 0), 1)`.
These extensions are available after class too; the four core reports are the classroom minimum.

## Practice 8 tasks — Window Functions

Open [the starter](../work/practice-08.sql). Use `reporting_lab.results` for every task.
Window functions let a row carry a group statistic, position, or ordered history while retaining its identity.

| Column | Meaning |
|---|---|
| `student_id` | Fictional student identifier |
| `offering_id` | Fictional course-offering identifier |
| `enrolled_on` | Enrolment date used to order the exercise history |
| `grade` | Numeric grade from 0–100, or NULL when ungraded |

One row represents a student in an offering; `(student_id, offering_id)` is the key. There are fourteen
rows across two offerings, with twelve numeric grades and two NULLs. A grade of zero is graded, so use
`grade IS NOT NULL` when a task asks for graded rows. P8-1, P8-2, P8-3 and P8-7 use only graded rows;
P8-4, P8-5, P8-6 and P8-8 retain all results. Tied grades, equal enrolment dates and a missing calendar
date are deliberate. Enrolment order is the exercise's history rule; it does not establish when grades were awarded.

The three teaching ideas and outcomes are:

- **Window aggregates retain detail rows.** Attach group context and explain the contrast with GROUP BY.
- **Ranking expresses a selection policy.** Handle ties deliberately and use an outer query for top-N.
- **Ordered windows define history and frames.** Compute running totals and explain which rows contribute.

Start with this supplied small demonstration, unrelated to the exercise answers:

```sql
WITH demo(team, points) AS (VALUES ('A', 2), ('A', 4), ('B', 9))
SELECT team, points, AVG(points) OVER (PARTITION BY team) AS team_average
FROM demo
ORDER BY team, points;
```

Compare it with the same demo using `SELECT team, AVG(points) ... GROUP BY team`.
The window version retains each detail row. Use this syntax guide; include only the parts your task needs:

```sql
function(...) OVER (
    PARTITION BY ...
    ORDER BY ...
    ROWS BETWEEN ... AND ...
)
```

`PARTITION BY` separates independent groups. Window `ORDER BY` controls calculation order; the query's
final `ORDER BY` controls displayed order. WHERE filters the input **before** window calculations.
You can use windows in SELECT and ORDER BY; filter a computed window result in an outer query or CTE.

<!-- rumdl-disable MD013 -->

| Optional | Task | Execute | Explain and save |
|:---:|---|---|---|
| false | P8-1: A grade in its group | Filter results to `grade IS NOT NULL`, retaining the zero grade. For every remaining row, calculate AVG(grade) and COUNT(*) with OVER (PARTITION BY offering_id), without window ordering. Add grade minus that offering average. Return `offering_id, student_id, grade, offering_average, graded_count, above_average`, ordered by offering_id and student_id. Keep every graded detail row. | Predict and check the output row count. Choose one offering and show that its average/count repeat on its detail rows; trace one grade-minus-average calculation and interpret its sign. Explain why GROUP BY alone would collapse the detail, why these windows use the whole offering, and how filtering ungraded rows before the windows defines their input. |
| false | P8-2: Three ranking policies | Use graded rows, partitioned by offering_id. Calculate ROW_NUMBER ordered by grade descending and student_id ascending; calculate RANK and DENSE_RANK ordered by grade descending only. Return `offering_id, student_id, grade, position, grade_rank, dense_grade_rank`, ordered by offering_id and position. Keep all three numbering columns in the same query for direct comparison. | Trace a tied pair and the next lower grade in each offering. Identify which functions share positions and which leave gaps. Explain why student_id makes ROW_NUMBER deterministic but would change the peer definition if added to RANK/DENSE_RANK. Distinguish each window's ordering from the final display ordering and state a report policy each numbering could support. |
| false | P8-3: Exactly two students per offering | In a CTE, filter to graded rows and calculate ROW_NUMBER per offering using grade descending, then student_id ascending. In the outer query retain positions 1 and 2. Return `offering_id, student_id, grade, position`, ordered by offering_id and position. Apply the window before selecting the winners, so each offering supplies its own two rows. | Verify that each offering contributes exactly two students and explain the smaller-ID tie-break at the selection boundary. Explain why a window result cannot be filtered in the same-level WHERE, and why a single LIMIT 2 would not implement two per offering. Predict which boundary membership changes with grade-only RANK when everyone tied at second place must be included. |
| false | P8-4: Running registration count | Group all fourteen results by enrolled_on in a `daily` CTE, counting rows regardless of grade. Apply SUM(daily_count) OVER with date ordering and `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. Return `enrolled_on, daily_count, running_count`, ordered by enrolled_on. Preserve one output row per observed date rather than per student. | Trace the contributing daily rows for a middle date and the final date. Check that the first cumulative count equals its daily count and the last equals the number of input results. Explain why daily aggregation precedes the window, why NULL grades still count enrolments, and why there is no row for the missing calendar date. Describe how this frame grows across the ordered dates. |
| true | P8-5: Previous result and change | Keep all fourteen results. In a CTE, calculate LAG(grade) per student ordered by enrolled_on and offering_id, aliasing it previous_grade. In the outer query add grade minus previous_grade as grade_change. Return `student_id, offering_id, enrolled_on, grade, previous_grade, grade_change`, ordered by student_id, enrolled_on and offering_id. Preserve NULLs instead of substituting zero. | Trace one student's two-row history and interpret the change's sign. Explain the first row per student and the offering-ID tie-break for equal dates. Find a NULL previous_grade caused by an actual ungraded preceding row, and distinguish it from the absence of a preceding row. Explain NULL subtraction and why filtering ungraded rows first would change the history being compared. |
| true | P8-6: Moving average | Reuse P8-4's daily-count CTE over all results. Calculate AVG(daily_count) OVER ordered by enrolled_on with `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW`. Return `enrolled_on, daily_count, last_three_observations_average`, ordered by enrolled_on. Retain a numeric average; do not add missing dates or replace this frame with a calendar interval. | List the contributing observed dates for the first, second and last output rows, and calculate the last average by hand. Explain why the initial windows contain fewer than three rows and why February 4's absence does not add a zero. State the difference between a three-observation average and a three-calendar-day average, including what extra calendar construction the latter would need. |
| true | P8-7: Balanced grade groups | Filter to graded rows and apply NTILE(3) per offering, ordered by grade descending and student_id ascending. Return `offering_id, student_id, grade, grade_band`, displayed by offering_id, grade descending and student_id. Assign a group to every graded row; do not aggregate the output or substitute fixed score thresholds. | Count the rows assigned to each band within each offering and locate an equal-grade pair split across bands. Explain why balancing row counts can split peers, why student_id stabilises that split, and how this differs from RANK or a rule such as grade >= 80. State when equally sized groups would be useful and when preserving tied grades would be a better policy. |
| true | P8-8: First and latest grade | Keep all fourteen results. Partition by student and order by enrolled_on, then offering_id. Add FIRST_VALUE(grade) as first_grade; add LAST_VALUE(grade) without an explicit frame as default_last_grade; add LAST_VALUE(grade) with `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` as latest_grade. Return `student_id, offering_id, enrolled_on, grade, first_grade, default_last_grade, latest_grade`, displayed by student/history order. | Find a row where default_last_grade and latest_grade differ, and trace the frame endpoint used by each. Explain why the unique history ordering makes the default LAST_VALUE follow the current row here, while the full frame reaches the student's final row. Trace a latest NULL and a first NULL without skipping either. Explain why “latest” follows enrolment order and does not mean the highest grade or most recently awarded grade. |

<!-- rumdl-enable MD013 -->

An aggregate window without ORDER BY uses the whole partition. With ORDER BY, the default frame can include
all peers at the current ordering value. Use the explicit ROWS frames supplied here to name the intended
input. P8-4 and P8-6 aggregate to one row per date first, so dates uniquely order those daily rows.

## Timing, checkpoints, and evidence

<!-- rumdl-disable MD013 -->

| Minutes | Practice 7 | Practice 8 |
|---:|---|---|
| 0–15 | P6 recall, readiness, UTC/boundary demo, P7-1; compare solution | Recall grouped counts, switch roles, short window demo, P8-1; compare solution |
| 15–30 | FILTER demo, P7-2; compare solution | Ranking demo, P8-2; compare solution |
| 30–45 | Calendar-series demo, P7-3; compare solution | CTE/outer-filter reminder, P8-3; compare solution |
| 45–60 | DISTINCT ON demo, P7-4; compare solution and individual exit | Explicit-frame demo, P8-4; compare solution |
| 60–75 | Assignment 2 evidence orientation | Apply feedback to core queries; ready students choose P8-5 to P8-8 |
| 75–80 | Record assignment feedback and next action | Individual window exit, review output and save evidence |

<!-- rumdl-enable MD013 -->

Each 15-minute cycle includes 10 minutes of writing/running with a brief demonstration and TA help, then
a 5-minute comparison. Check saved SQL, output and reasoning at minutes 15, 30, 45 and 60.
Keep your own evidence even when working in pairs. All four optional tasks are ungraded extensions for
early finishers or later completion; they do not increase the mandatory classroom workload.

P7 exit: an association has registered, cancelled and registered events. How do you determine its state
at a cutoff? Explain where the time predicate and active-status predicate belong.

P8 exit: choose between exactly two students and everyone tied at second place. Name the ranking
function and tie rule; explain where you filter its result. Retrieve both exits briefly at P9 with feedback.

P8's final 20 minutes belong to the window workshop, with no assignment studio.
After class, read the released Assignment 2 brief. Performance investigations continue in P9, where
scan/buffer observations support the before/after index experiment.

## PostgreSQL references

- [Aggregate FILTER and ordered aggregates](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-AGGREGATES)
- [Date/time functions](https://www.postgresql.org/docs/18/functions-datetime.html)
- [Generating series](https://www.postgresql.org/docs/18/functions-srf.html)
- [DISTINCT ON](https://www.postgresql.org/docs/18/sql-select.html#SQL-DISTINCT)
- [EXISTS](https://www.postgresql.org/docs/18/functions-subquery.html#FUNCTIONS-SUBQUERY-EXISTS)
- [Aggregate functions](https://www.postgresql.org/docs/18/functions-aggregate.html)
- [Window tutorial](https://www.postgresql.org/docs/18/tutorial-window.html)
- [Window functions and frames](https://www.postgresql.org/docs/18/functions-window.html)
