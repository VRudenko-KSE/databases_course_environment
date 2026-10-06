# Practices 7–8 — SQL Guide

Use this guide alongside [the Practice 7 and 8 tasks](practices-07-08.md). It introduces practical SQL topics
that extend Lecture 3 and are separate from Lecture 4’s storage material. Examples use their own small data.

Run the small examples below in your SQL interface before adapting them to the task fixtures.

## 1. UTC Timestamps and Half-Open Periods

`timestamptz` represents an instant; the session time zone controls its displayed local time and date cast. With
UTC set, the following September 30 instant remains September 30. A report interval uses
`>= start` and `< next_period_start`, so every instant on the final day is eligible.
An endpoint at September 30 midnight misses the rest of that day.

```sql
SET TIME ZONE 'UTC';
SELECT TIMESTAMPTZ '2026-09-30 23:59:59+00'::date AS report_date,
       TIMESTAMPTZ '2026-09-30 23:59:59+00'
           < TIMESTAMPTZ '2026-10-01 00:00:00+00' AS before_cutoff;
```

Result: `2026-09-30` and `true`. For a state-at-cutoff report, consider earlier history too; a month's event list
and the state at its end need different inputs. Read [PostgreSQL date/time types and time
zones](https://www.postgresql.org/docs/18/datatype-datetime.html#DATATYPE-TIMEZONES).

## 2. FILTER — Several Metrics from the Same Input

```sql
WITH demo(state) AS (VALUES ('open'), ('closed'), ('open'))
SELECT COUNT(*) AS all_events,
       COUNT(*) FILTER (WHERE state = 'open') AS open_events,
       COUNT(*) FILTER (WHERE state = 'closed') AS closed_events
FROM demo;
```

Result: `3, 2, 1`. Each FILTER selects rows for its own aggregate; a query-level WHERE would remove rows before all
aggregates. After a left join, count a non-NULL matched key when measuring matches. Read [aggregate
expressions](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-AGGREGATES).

## 3. `generate_series`, LEFT JOIN, COALESCE, and CTEs

```sql
WITH calendar AS (
    SELECT DATE '2026-01-01' + offset_days AS report_date
    FROM generate_series(0, 2) AS days(offset_days)
), observed(report_date, event_count) AS (
    VALUES (DATE '2026-01-01', 2), (DATE '2026-01-03', 1)
)
SELECT c.report_date, COALESCE(o.event_count, 0) AS event_count
FROM calendar AS c
LEFT JOIN observed AS o USING (report_date)
ORDER BY c.report_date;
```

Result: January 1–3 with counts `2, 0, 1`. The series supplies a row for January 2; the left join retains it;
COALESCE replaces its missing count. A grouped event query alone cannot invent that date. WITH names intermediate
results for **this one statement**. Read [generate_series](https://www.postgresql.org/docs/18/functions-srf.html),
[COALESCE](https://www.postgresql.org/docs/18/functions-conditional.html#FUNCTIONS-COALESCE-NVL-IFNULL), and
[CTEs](https://www.postgresql.org/docs/18/queries-with.html).

## 4. DISTINCT ON — Choose One Ordered Row per Key

```sql
WITH demo(device, version, reading) AS (
    VALUES ('A', 1, 10), ('A', 2, 15), ('B', 1, 7)
)
SELECT DISTINCT ON (device) device, version, reading
FROM demo
ORDER BY device, version DESC;
```

Result: `A, 2, 15` and `B, 1, 7`. DISTINCT ON is a PostgreSQL extension that retains the first ordered row per key;
ordinary DISTINCT removes duplicate selected rows. Its keys must lead ORDER BY. Additional ordering expressions
decide which row wins; resolve ties explicitly. Read [the DISTINCT
clause](https://www.postgresql.org/docs/18/sql-select.html#SQL-DISTINCT).

For a current-state report, first discard events at or after the cutoff, then choose the latest remaining event for
each registration, then test its status outside that selection. Filtering to registered events first can recover an
older active event even when a later cancellation exists. P7 defines descending timestamp, then descending event ID
as the winner rule.

## 5. Optional Reporting Tools

- **EXISTS:** tests whether a correlated subquery has any matching row. Connect its student key to the outer
  student. Several matching cancellations still produce one outer student row. Read
  [EXISTS](https://www.postgresql.org/docs/18/functions-subquery.html#FUNCTIONS-SUBQUERY-EXISTS).
- **Ordered text:** `STRING_AGG(name, ', ' ORDER BY name)` joins non-NULL names in the stated order. Keep an empty
  list NULL. The list's order is separate from final result ordering. Read [aggregate
  functions](https://www.postgresql.org/docs/18/functions-aggregate.html).
- **Weekly buckets:** `date_trunc('week', timestamp)::date` labels a Monday-based week in the chosen reporting time
  zone. Filter the month first; its first week's label can be in the previous month. Read
  [date_trunc](https://www.postgresql.org/docs/18/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC).
- **Safe ratios:** `ROUND(100.0 * numerator / NULLIF(denominator, 0), 1)` uses numeric division and makes a zero
  denominator NULL. An undefined ratio remains NULL. Define what both counts measure before calling the result a
  percentage. Read [NULLIF](https://www.postgresql.org/docs/18/functions-conditional.html#FUNCTIONS-NULLIF) and
  [mathematical operators](https://www.postgresql.org/docs/18/functions-math.html).

## 6. OVER and PARTITION BY — Keep Rows and Add Group Context

```sql
WITH demo(team, points) AS (VALUES ('A', 2), ('A', 4), ('B', 9))
SELECT team, points,
       AVG(points) OVER (PARTITION BY team) AS team_average
FROM demo
ORDER BY team, points;
```

Three detail rows remain: A's two rows each carry average 3; B's row carries 9. A GROUP BY team query would produce
two group rows. PARTITION BY identifies independent groups; omitting window ORDER BY gives this aggregate the whole
partition. WHERE defines the input before windows. Window ordering controls calculations; the final ORDER BY
controls display. Read [the window tutorial](https://www.postgresql.org/docs/18/tutorial-window.html).

## 7. Ranking, Ties, and Filtering after a Window

```sql
WITH demo(player_id, points) AS (
    VALUES (1, 10), (2, 8), (3, 8), (4, 5)
), ranked AS (
    SELECT player_id, points,
           ROW_NUMBER() OVER (ORDER BY points DESC, player_id) AS position,
           RANK() OVER (ORDER BY points DESC) AS points_rank,
           DENSE_RANK() OVER (ORDER BY points DESC) AS dense_points_rank
    FROM demo
)
SELECT * FROM ranked
ORDER BY position;
```

| Points | ROW_NUMBER | RANK | DENSE_RANK |
| --- | --- | --- | --- |
| 10 | 1 | 1 | 1 |
| 8 | 2 | 2 | 2 |
| 8 | 3 | 2 | 2 |
| 5 | 4 | 4 | 3 |

ROW_NUMBER assigns unique positions, made deterministic here by player ID. RANK shares ties and leaves gaps;
DENSE_RANK shares ties without gaps. Add the ID to ROW_NUMBER's order, but leave it out of grade-based ranks to
preserve grade peers.

To select exactly two players, rerun the complete statement with its final SELECT replaced by:

```sql
SELECT * FROM ranked
WHERE position <= 2
ORDER BY position;
```

The outer query filters the computed positions. A same-level WHERE cannot use a window result. In the demo,
`points_rank <= 2` instead includes three players because second place is tied. Add PARTITION BY when each offering
needs its own selection; a single LIMIT caps the whole result. Read [ranking
functions](https://www.postgresql.org/docs/18/functions-window.html) and [the tutorial's outer-query
example](https://www.postgresql.org/docs/18/tutorial-window.html).

## 8. ROWS Frames — Name the Contributing Observations

```sql
WITH daily(day, event_count) AS (
    VALUES (DATE '2026-01-01', 2),
           (DATE '2026-01-03', 4),
           (DATE '2026-01-04', 3)
)
SELECT day, event_count,
       SUM(event_count) OVER (
           ORDER BY day
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_count,
       AVG(event_count) OVER (
           ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS last_three_observations_average
FROM daily
ORDER BY day;
```

The running totals are `2, 6, 9`; moving averages are `2, 3, 3`. The expanding frame starts at the first row; the
moving frame keeps at most the current row and two earlier rows. January 2 supplies no row. ROWS measures
observations, so three rows need not mean three consecutive days.

P8 counts detail rows by date before applying the window to daily totals. With window ORDER BY, the default frame
reaches the current row's last peer; an explicit ROWS frame states the required contributors. Read [window syntax
and frames](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-WINDOW-FUNCTIONS).

## 9. Optional Window Tools — History, Bands, and Frame Endpoints

- **LAG(grade):** reads the previous ordered row in the student's partition. NULL can mean no previous row or an
  actual previous row with a NULL grade. Filtering ungraded rows first changes that history.
- **NTILE(3):** divides ordered rows into three groups with sizes as equal as possible. It can split equal grades;
  it does not define fixed score thresholds.
- **FIRST_VALUE / LAST_VALUE:** read the first or last value inside the frame. With a unique ordering, default
  LAST_VALUE follows the current row. To reach the partition's final row,
  use `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`.
  PostgreSQL retains NULL values for these functions.

Read [the window-functions reference](https://www.postgresql.org/docs/18/functions-window.html) and [frame
syntax](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-WINDOW-FUNCTIONS). In P8, order each
student's history by enrolment date and then offering ID. “Latest” follows that exercise order.
