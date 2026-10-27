# Practice dataset guide

The default `practice` schema is a small, fixed teaching fixture: 41 rows across four tables. It stays readable in
query output while covering joins, aggregation, NULL handling, and relational constraints.

| Table | Grain and key | Main relationships | Rows |
|---|---|---|---:|
| `courses` | One course, `course_id` | Parent of offerings | 8 |
| `students` | One student, `student_id` | Parent of enrolments; unique email | 7 |
| `course_offerings` | One course section in one term, `offering_id` | Course FK; unique course/term/section | 8 |
| `enrolments` | One student in one offering, composite key | Student and offering FKs; grade is NULL or 0–100 | 18 |

`courses.seats_available` remains the introductory Week 1 snapshot. It does not represent capacity or derive from
the new offering and enrolment rows.

## Coverage Through Week 6

- Week 1: the original eight courses and every value are unchanged for basic `SELECT`, filtering, sorting, aliases,
  expressions, and NULL concepts.
- Week 2: students, repeated course offerings, and enrolments model a many-to-many relationship. Primary keys,
  foreign keys, a composite key, unique email and course/term/section rules, and the grade check support constraint
  and anomaly discussions.
- Week 3: the fixture supports inner and outer joins, join multiplication, `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`,
  `GROUP BY`, `HAVING`, set operations, subqueries, CTEs, `CASE`, `COALESCE`, and SQL NULL behavior.
- Week 4: [Practices 7–8](practices-07-08.md) build calendar metrics and latest-state reports from eighteen
  fictional `activity_lab.registration_events`, then introduce windows using fourteen fictional
  `reporting_lab.results`. Each session has four core/four optional queries. Canonical enrolments remain
  unchanged. The synthetic 40,000-row storage_lab fixture remains an optional storage demonstration.
- Week 5: [Practices 9–10](practices-09-10.md) use a prepared 2,000,000-enrolment fixture in `index_lab`.
  Four core tasks and one optional task per session connect index experiments to earlier SQL reports.
- Week 6: [Practices 11–12](practices-11-12.md) add `advanced_lab` for requirements, room bookings,
  pagination and portal-event analysis. SQL correctness and index experiments remain paired;
  a separate external demonstration illustrates LSM storage.

Deliberate cases include a student with no enrolments, courses with no offering, an empty offering, an offering with
only NULL grades, and another with mixed NULL and numeric grades. Grades contain 0, 100, repeats, and tied offering
averages. Course 101 runs in two terms and two sections, and student 1 retakes it. Cohorts and hometowns repeat, with
some hometowns NULL.

This query retains the empty offering and filters grouped results:

```sql
SELECT o.offering_id,
       c.title,
       COUNT(e.student_id) AS enrolled_count,
       COUNT(e.grade) AS graded_count,
       AVG(e.grade) AS average_grade
FROM practice.course_offerings AS o
JOIN practice.courses AS c USING (course_id)
LEFT JOIN practice.enrolments AS e USING (offering_id)
GROUP BY o.offering_id, c.title
HAVING COUNT(e.student_id) < 3
ORDER BY o.offering_id;
```

With a `LEFT JOIN`, `COUNT(*)` would count the placeholder row for an empty offering as 1. Counting the non-null
child key with `COUNT(e.student_id)` correctly reports 0. `COUNT(e.grade)` also demonstrates that aggregate
counting ignores NULL grades. The repeated terms, cohorts, grades, and missing values also support `UNION` or
`INTERSECT` comparisons, CTE-based aggregates, `CASE` bands, and `COALESCE` labels.

## Reporting and window fixtures for Practices 7–8

The [P7–8 handout](practices-07-08.md) defines all sixteen queries, their required output and the evidence
to save. Each session has four core tasks and four optional extensions. Use these dedicated lab tables
for those exercises rather than the canonical `practice.enrolments` table.

| Table | One row represents | Rows |
|---|---|---:|
| `activity_lab.students` | A fictional student | 7 |
| `activity_lab.workshops` | A campus workshop | 4 |
| `activity_lab.registrations` | A unique student/workshop association | 10 |
| `activity_lab.registration_events` | A registered/cancelled status event for an association | 18 |
| `reporting_lab.results` | A fictional student in an offering, with an enrolment date and optional grade | 14 |

P7 deliberately separates **actions during a period** from **state at a cutoff**. Events include August
history, September boundary timestamps and an October event. One registration remains active from August
without any September action; another has equal-time events resolved by the larger event_id. A quiet day,
cancellation/re-registration and workshops without active participants support calendar and list reports.
Use UTC for date casts and weekly buckets, and keep the fixed period/cutoff from the handout.

The four core P7 queries select September events, count daily statuses, fill a complete calendar and recover
latest registration state. The optional queries find students with cancellation history, build ordered
participant lists, group September activity into weeks and define an event ratio with an explicit denominator.
An event ratio describes the chosen event counts; it is not a percentage of unique students.

P8 has two offerings, twelve graded rows and two NULL grades. Zero is a real grade. Ties, equal enrolment
dates and a missing calendar date make ranking policies and window frames observable. The core tasks attach
group averages/counts, compare three ranking functions, select top-N within each offering and compute running
daily counts. Extensions compare previous grades, average the last three observed dates, use NTILE for
balanced groups and compare first/last values under different frames. Tasks that retain ungraded rows must
keep their NULLs; the declared enrolment ordering defines the exercise history.

For an existing database, install only missing lab schemas as described in
[Prepare the fixture](practices-07-08.md#prepare-the-fixture). If an earlier lab baseline is already installed,
save lab edits before using the documented P7–8 checkpoint; it replaces activity_lab and reporting_lab
while preserving earlier practice schemas, storage_lab and host work files.

## Index Workshop Fixture for Practices 9–10

The [P9/P10 handout](practices-09-10.md) explains setup, ten tasks, experiment state and scoped recovery.
Migration 60 creates 100,000 students, 500 courses, 10,000 offerings, 2,000,000 enrolments
and a supplied 1,000-row batch.
Each student has 20 registrations; offering 10000 is empty. Current registration statuses have different frequencies.
NULL/zero grades, grade ties, equal timestamps, explicit UTC date boundaries and a quiet March 4 support report checks.
Only the main table's primary-key and unique-constraint indexes exist at baseline. Students add candidate indexes.

This snapshot uses `registered_at` and current `status`, not a status-event timeline: cancellation counts by
registration date differ from the event counts in P7. The pair revisits joins, NULLs, grouping, date intervals,
CTEs, top-N windows, complete calendars and running totals. Partial indexes are P9's optional task;
covering indexes are P10's optional task. Measured INSERTs use only the disposable `index_write` schema.

Fresh installations load the seed automatically. Existing installations apply the missing migration once without
erasing previous work. The full P9/P10 checkpoint restores only index_lab/index_write; the index-only reset keeps
the seed and constraint indexes. Actual plan choices and times may differ across machines.

## Advanced SQL Fixture for Practices 11–12

[Migration 70](../sql/migrations/70-practices-11-12.sql) creates an independent `advanced_lab` schema:

| Table | One row represents | Rows |
| --- | --- | ---: |
| `programmes` | A study programme | 10 |
| `students` | A student in a programme | 10,000 |
| `courses` | A catalogue course | 30 |
| `requirements` | One required course in a programme | 27 |
| `attempts` | One recorded course attempt, possibly ungraded | 100,000 |
| `rooms` | A room with a seating capacity | 200 |
| `bookings` | One half-open room reservation interval | 200,000 |
| `portal_events` | One timestamped portal action | 240,000 |

[Migration 71](../sql/migrations/71-practices-11-12-edge-cases.sql) upgrades three background rows without
changing these totals. Apply it to existing installations too; the [readiness check](../sql/practices-11-12-ready.sql)
checks the revised cases as well as counts. Repeated attempts and NULL grades distinguish “any” from
“every required course.” Student 1 has mixed passing/failing attempts for a required course; student 6
passes only a non-required course. Attempt IDs do not encode chronology. Programme 10 has no
requirements. Adjacent bookings, an empty room, and tied timestamps exercise overlap and pagination.
Portal events include equal timestamps, gaps of 30, 30.5 and 31 minutes, missing days and
consecutive active-day runs. These are deliberately fictional teaching cases, not a real usage distribution.

Read the [handout](practices-11-12.md) for precise task parameters and use the
[SQL guide](practices-11-12-sql-guide.md) for syntax. The scoped checkpoint replaces only `advanced_lab`;
the index reset retains its rows and constraint indexes. Keep bookings unchanged during page comparisons.
Event sessions reset at the stated report boundary; they do not infer continuous sessions from earlier history.

## Optional Historical Access-Plan Sample

This older recipe is separate from the required P9/P10 seed. Run it only when exploring plans and buffers.
It creates an ordinary, separately named 18,000-row table so
`BUFFERS` reports shared blocks. Plain `CREATE TABLE AS` deliberately fails when the table already exists instead of
overwriting work. The observed plan and read/hit counts depend on PostgreSQL and cache state; `EXPLAIN ANALYZE`
executes the query. A shared read may be served by the operating-system cache; it does not prove physical disk I/O or
a cold-cache run.

```sql
CREATE TABLE practice.enrolment_access_sample AS
SELECT copy_number,
       e.student_id,
       e.offering_id,
       e.enrolled_on,
       e.grade
FROM generate_series(1, 1000) AS copies(copy_number)
CROSS JOIN practice.enrolments AS e;

ANALYZE practice.enrolment_access_sample;

EXPLAIN (ANALYZE, BUFFERS)
SELECT offering_id, COUNT(*) AS enrolment_copies, AVG(grade) AS average_grade
FROM practice.enrolment_access_sample
GROUP BY offering_id
HAVING COUNT(*) >= 2000;
```

See PostgreSQL's documentation for [`EXPLAIN`](https://www.postgresql.org/docs/current/sql-explain.html) and
[aggregate functions](https://www.postgresql.org/docs/current/functions-aggregate.html).

## Extending and resetting

[Practices 13–14](practices-13-14.md) use five independent runtime fixtures installed by
migrations 80, 83, 84, 86 and 88: two current-loan fixtures, protected workshop admission, room
capacity and exam staffing. Counter races and deadlock ordering use supplied reasoning examples. They do not
share mutable state with earlier labs. Each has its own starting-state check, reset and scoped
TA-assisted rebuild. The handout lists columns, identities, rules and the exact A/B step order.
These are correctness experiments, not large-data index benchmarks; completed repairs stay private.

Practices 3–4 use a separate student-built `library_lab` schema described in
[the library workshop handout](practices-03-04.md). Its start and checkpoint commands leave this university fixture
unchanged. The library recovery schema is supplied for teaching continuity; the student exercise begins with a
narrative and an empty diagram/workspace.

[Practices 5–6](practices-05-06.md) use separate `library_p5` and `library_p6` schemas created automatically by
the numbered `sql/migrations/` scripts on a fresh PostgreSQL volume. Both begin with three author links; P6 also
has mixed-fact repair inputs and live/stored loan reports. The
[Practice 3 fresh-start prerequisite](practices-03-04.md#fresh-start-prerequisite) resets the volume and verifies
all supplied stages. Restarting with an existing volume does not replay the migrations.

Add offerings with stable new `offering_id` values, then add enrolments that reference those IDs and existing student
IDs. Departments or instructors can become separate entities when a later topic requires them.

Existing Docker volumes do not rerun the seed after a file update. The scoped reset command in the main README drops
and recreates the whole `practice` schema, including the optional sample and any other edits there. It leaves the
`public` schema and host files unchanged.
