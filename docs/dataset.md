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

## Coverage through Week 4

- Week 1: the original eight courses and every value are unchanged for basic `SELECT`, filtering, sorting, aliases,
  expressions, and NULL concepts.
- Week 2: students, repeated course offerings, and enrolments model a many-to-many relationship. Primary keys,
  foreign keys, a composite key, unique email and course/term/section rules, and the grade check support constraint
  and anomaly discussions.
- Week 3: the fixture supports inner and outer joins, join multiplication, `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`,
  `GROUP BY`, `HAVING`, set operations, subqueries, CTEs, `CASE`, `COALESCE`, and SQL NULL behavior.
- Week 4: the optional disposable sample below is large enough to make page, buffer, and query-plan observations
  easier to see without burdening the default seed.

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

## Optional Week 4 access sample

Run this recipe only when exploring plans and buffers. It creates an ordinary, separately named 18,000-row table so
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

Practices 3–4 use a separate student-built `library_lab` schema described in
[the library workshop handout](practices-03-04.md). Its start and checkpoint commands leave this university fixture
unchanged. The library recovery schema is supplied for teaching continuity; the student exercise begins with a
narrative and an empty diagram/workspace.

Add offerings with stable new `offering_id` values, then add enrolments that reference those IDs and existing student
IDs. Departments or instructors can become separate entities when a later topic requires them.

Existing Docker volumes do not rerun the seed after a file update. The scoped reset command in the main README drops
and recreates the whole `practice` schema, including the optional sample and any other edits there. It leaves the
`public` schema and host files unchanged.
