# Practices 3–4 — Design, Build, and Improve a Library Database

Two 80-minute workshops with the scheduled break between them. All 160 teaching minutes are for demonstrations
and exercises; these two sessions have no separate Assignment 1 studio. Work in pairs, change driver after the
break, and keep an individual diagram, SQL files, predictions, and exit answers. Practice work is ungraded.

The TA demonstrates with the same campus lending library. This is a separate
practice scenario, not Assignment 1's workshop-registration model or a solution to its CSV-loading task.

## Prepare and Run

Use the existing Docker environment. From `course-environment`, run `docker compose up -d --wait` and
`docker compose ps`. Connect pgAdmin's Query Tool to `university` as `student`. New tables use `library_lab`.

Start Practice 3 with an empty workspace:

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/practice-03-start.sql
```

This **deletes all database objects in `library_lab`**. It leaves the original `practice` fixture, other schemas,
and your saved host files alone. Save your SQL before resetting. The general `reset-practice.sql` resets a different
schema and is not the recovery command for this pair.

Keep your SQL, diagram, and notes under `work/practice-03/` and `work/practice-04/`. These folders are visible
locally and in pgAdmin as **Course work**. Run a completed SQL file from `course-environment` through `/work`:

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/practice-03/01-schema.sql
```

Run `01-schema.sql`, `02-inserts.sql`, then `03-queries.sql` in that order. Change the filename in the command
for each step. See [Query and script workflows](query-and-script-workflows.md#run-your-own-saved-sql-file) for
pgAdmin file dialogs and permissions.
Execute type experiments one statement at a time in pgAdmin; keep TEMP-table experiments in the same Query Tool session.

If DDL work blocks the INSERT exercise, the TA may provide four **empty** tables with this recovery command:

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university \
  -f /course/sql/practice-03-schema-checkpoint.sql
```

The two lines above are one command; in PowerShell enter them as one line without the backslash. This replaces
`library_lab`; save your work first. Record which design decisions still need completion. The populated P4
checkpoint is for query/P4 recovery, not for rerunning the insertion exercise.

## Practice 3 Narrative

The campus library keeps a catalogue of book editions and tracks individual physical copies. Two editions may have
the same title, and a catalogue entry may exist before the library acquires a copy. Each edition has its own ISBN.
For this exercise, one `books` row means one catalogued edition; editions of an abstract literary work are not
modelled separately. All names and catalogue identifiers in the fixture are synthetic.

Borrowers have a stable internal ID and a required unique card code. Card codes can begin with zero. People may
share a name, and a registered borrower need not have borrowed anything. Each physical copy has an internal ID,
a required unique inventory code of at most 12 characters, a nonnegative replacement cost, and a retirement flag.
The catalogue describes the book; the inventory describes the physical object. Costs are exact amounts in UAH.

A loan records one borrowing event: one borrower, one physical copy, a borrowing instant, a due instant, and an
optional return instant. A borrower can borrow the same copy again after returning it. Every loan has an internal
ID; the same physical copy cannot have two recorded loan starts at the same instant. The due and return instants
cannot precede the borrowing instant. A NULL return means the copy has not been returned, not an empty string or
a time of zero. These declarations do not yet prevent overlapping loans or borrowing a retired copy: investigate
those gaps in Practice 4.

### Draw the Model in draw.io

1. Open [draw.io](https://app.diagrams.net/); choose **Device** if asked where to save the file.
2. Create a blank diagram.
3. Under **More Shapes**, enable **Entity Relation**. Use entity/table shapes and relationship connectors.
4. Draw entities and attributes. Mark PK, FK, and alternate unique keys. For a multi-column key, mark the group.
5. Label both relationship ends with their minimum and maximum cardinality. Read every relationship aloud in both
   directions. A mandatory child reference does not require every parent to have a child.
6. Save your diagram as `work/practice-03/library.drawio`; export SVG or PNG beside it. Keep the editable source.

Use explicit labels such as `1` and `0..many` if connector symbols are unfamiliar. The meaning matters more than
styling. If the browser tool is unavailable, use the installed draw.io desktop application, or sketch on paper and
transfer the sketch later. Keep your own diagram; the TA reference is for review after the exercise.

### P3-M — Model and Explain

Before writing SQL, state one row's meaning for each table. Identify entities, relationship facts, keys, and optional
participation. Explain where the loan dates belong. Test your keys using the two borrowers with the same name and
the two loan events for borrower 1 and copy 101. Record your reasoning in `work/practice-03/model.md`.

### P3-T — Choose Data Types Experimentally

Create `work/practice-03/types.sql` if you want to save your experiments. For each comparison below, record a prediction,
observed value or error, chosen type, and reason. Split the comparisons within your pair, then explain every result
to one another.

<!-- rumdl-disable MD013 -->

| Comparison | Decision to Justify |
|---|---|
| `text` versus integer for `'0001'` | Is this identifier a quantity? Must leading zeroes survive? |
| `smallint` versus integer for 40000 | What is the permitted range and expected growth? |
| `numeric(8,2)` versus double precision | What does exact cost arithmetic require? What happens to a third decimal? |
| `text` versus `varchar(12)` | Does the narrative impose a length limit? A bound is not a universal speed improvement. |
| `date`, `timestamp`, `timestamptz` | Is the value a calendar day, a local wall-clock time, or an instant? |
| NULL, zero, empty string; boolean | Which values mean missing, zero cost, an empty name, and retired? |
| Explicit integer versus generated identity | Who allocates IDs? Does generation enforce another unique business key? |

<!-- rumdl-enable MD013 -->

Use `SET TIME ZONE 'UTC'`, then `SET TIME ZONE 'Europe/Kyiv'` to compare timestamp displays. A `timestamptz`
represents an instant; it does not retain the original time-zone name. Use explicit offsets in fixture inserts.
See PostgreSQL's [types](https://www.postgresql.org/docs/18/datatype.html) and
[identity columns](https://www.postgresql.org/docs/18/ddl-identity-columns.html).

### P3-S — Build the Schema

Write your own `work/practice-03/01-schema.sql`. Translate your model into four tables. Use these shared
column names so the later exercises and fallback match; justify the selected types in your model notes.

<!-- rumdl-disable MD013 -->

| Table | Required Columns | Rules |
|---|---|---|
| `borrowers` | `borrower_id`, `full_name`, `card_code` | ID primary key; name required; card required and unique |
| `books` | `book_id`, `title`, `isbn`, `published_on` | ID primary key; title required; ISBN required and unique; publication day optional |
| `copies` | `copy_id`, `book_id`, `inventory_code`, `replacement_cost`, `retired` | ID primary key; required book reference; required unique code, max 12 characters; required cost ≥ 0; required boolean default false |
| `loans` | `loan_id`, `borrower_id`, `copy_id`, `borrowed_at`, `due_at`, `returned_at` | ID primary key; required borrower/copy references; unique copy/start pair; borrowing/due instants required; return optional; due/return not earlier than borrowing |

<!-- rumdl-enable MD013 -->

Name constraints so failures can be explained. Use the scaffold to write one parent table and one child table
yourself; then complete the other two by adapting your own definitions. Inspect all four definitions with the TA.
Adding a row changes the instance. Adding a rule or column changes the schema. Give your own example of each.

### P3-I — Insert the Fixture

Write the inserts for all rows in the tables below in `work/practice-03/02-inserts.sql`. Insert parents before dependent rows.
Explain the parent-first order before running the file.
Use the supplied integer IDs for reproducibility and demonstrate `RETURNING` on one insert. Duplicate names are
intentional. Do not combine or discard the two people.

<!-- rumdl-disable MD013 -->

| borrower_id | full_name | card_code |
|---:|---|---|
| 1 | Olena Bondar | 0001 |
| 2 | Maksym Levchenko | 0002 |
| 3 | Olena Bondar | 0003 |

<!-- rumdl-enable MD013 -->

<!-- rumdl-disable MD013 -->

| book_id | title | isbn | published_on |
|---:|---|---|---|
| 10 | Learning Databases | 9780000000011 | 2024-03-01 |
| 20 | City Gardens | 9780000000028 | 2023-06-15 |
| 30 | Night Maps | 9780000000035 | NULL |

<!-- rumdl-enable MD013 -->

<!-- rumdl-disable MD013 -->

| copy_id | book_id | inventory_code | replacement_cost | retired |
|---:|---:|---|---:|---|
| 101 | 10 | LIB-001 | 125.50 | false |
| 102 | 10 | LIB-002 | 125.50 | false |
| 201 | 20 | LIB-003 | 80.00 | false |
| 202 | 20 | LIB-004 | 0.00 | true |

<!-- rumdl-enable MD013 -->

All following instants use offset `+03`. Write the offset explicitly in every non-NULL timestamp literal.

<!-- rumdl-disable MD013 -->

| loan_id | borrower_id | copy_id | borrowed_at | due_at | returned_at |
|---:|---:|---:|---|---|---|
| 1001 | 1 | 101 | 2026-09-01 09:00 | 2026-09-08 09:00 | 2026-09-05 10:00 |
| 1002 | 2 | 201 | 2026-09-02 11:00 | 2026-09-09 11:00 | NULL |
| 1003 | 1 | 101 | 2026-09-10 09:00 | 2026-09-17 09:00 | NULL |

<!-- rumdl-enable MD013 -->

### P3-Q — Read What You Built

Complete Q1–Q5 below in `work/practice-03/03-queries.sql`. State each result's grain and which
table supplies each output column. Explain why projecting only a title can produce two equal output values.
Use `IS NULL` for unreturned loans. Use `ORDER BY` whenever the question requires a defined order.

- Q1: Return `borrower_id` and `full_name` for card code `0001`.
- Q2: Return `loan_id` for unreturned loans, ordered by `loan_id`.
- Q3: For borrower 1, return `loan_id` and book title, ordered by borrowing time, then loan ID. Join loans through
  copies to books.
- Q4: Repeat Q3 with only the title in the output. Explain repeated values.
- Q5: Return `copy_id` for non-retired copies with a positive replacement cost, ordered by `copy_id`.

**Individual exit:** identify the two repeat-loan rows, explain their identity, and show one diagram edge that
matches a foreign key. Save your SQL and diagram. No work is required during the break.

## Practice 4 — Test and Improve

Switch driver/explainer roles. Save your Practice 3 files before using the common starting checkpoint:

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/practice-04-checkpoint.sql
```

This replaces **only `library_lab`**, including any previous Practice 4 database work. Expect books 3, borrowers 3,
copies 4, loans 3. The supplied schema is a recovery resource, not evidence that you independently completed P3.
Students who finished P3 should compare their choices with it and record one difference before proceeding.

### P4-C — Test Rules and Their Limits

Use [`01-constraints.sql`](../work/practice-04/01-constraints.sql). For each numbered case, predict the outcome,
write an INSERT or UPDATE, observe the actual error or result, and name the rule. Evaluate each case independently
from the baseline. Include successful boundary and missing-value cases, not just failures.

For one case in pgAdmin, execute `BEGIN`, then your statement. Inspect the result, then execute `ROLLBACK` even
after an error. Do not run all three as one selected batch when you need to inspect the middle result. Rollback
also undoes successful changes, keeping the next case independent. Outside a transaction, previously committed
writes are not undone by a later failure.

For file execution, save **one** case as `work/practice-04/case.sql` with `BEGIN`, your statement, and `ROLLBACK`:

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/practice-04/case.sql
```

On an intentional failure, psql exits nonzero and disconnects; the open transaction is rolled back. Record the
actual constraint error, not just the exit code. This file route is independent for each run.

**Deeper question:** test a different-start loan that overlaps an existing loan and a loan of a retired copy.
Explain why valid foreign keys and row-level date checks are insufficient. Propose the missing rule in words.
Implementing concurrency-safe lending rules is an extension, not a guarantee of the base schema.

### P4-A — Change the Relationship

Use [`02-authors.sql`](../work/practice-04/02-authors.sql). An earlier catalogue records one author per book:
book 10 → author 201, book 20 → author 202, book 30 → no known author. The new requirement allows co-authors,
and an author can contribute to many books. Author 201 is Iryna Lis; author 202 is Taras Melnyk.

Create `authors(author_id, full_name)` and
`book_authors(book_id, author_id, credit_order)`. Preserve the two existing links, then add author 202 to book 10
in position 2. Store one association per row; no comma-separated author IDs. Prevent duplicate pairs, require
positive credit order, and prevent two authors having the same position for one book. Book 30 may remain unlinked.
Update your draw.io model. Write a joined query with one row per book/author link, ordered by book ID and credit order.

### P4-R — Improve Fact Placement

Use [`03-repair.sql`](../work/practice-04/03-repair.sql). The self-contained input tables there are temporary,
so run their setup and your solution in one Query Tool session, or run the whole file as one `psql` invocation.
These are small variations, not extra application
features. Keep every original association and distinguish a deliberate business rule from a sample coincidence.

- **R1:** An array cell `ARRAY[201, 202]` hides separate book/author links. Write the three association rows and compare with
  P4-A. Explain how the row key supports individual links. This is the 1NF connection.
- **R2:** A book/author table repeats title and author name. Rename only one copy of a title; show the inconsistency.
  Explain how adding an unlinked book and deleting its last author link expose two more problems. Split the facts
  according to their dependencies, then join the results to reconstruct all three original rows. This is the 2NF
  connection: descriptions depend on only part of the pair key.
- **R3:** Each book has one publisher; the only candidate key in this reduced example is book ID. Publisher name
  depends on publisher ID. Split the provided records into books and publishers, and reconstruct them. This is the
  3NF connection. Adding an artificial row ID would not remove that dependency.
- **R4:** Reconstruct a two-person address example using IDs, then deliberately join on their shared name. Count and
  inspect the invented combinations. Explain why row counts alone are not a complete correctness proof.

Normal forms name problems you just repaired. They are not a separate memorization block. In a schema with several
candidate keys, examine dependencies against all of them; choosing one primary key does not erase the others.

### P4-D — Observe a Stale Report

Use [`04-report.sql`](../work/practice-04/04-report.sql). Build a view and a stored snapshot of loans with borrower
names and book titles. Update borrower 1's name to `Olena Updated`. Query both representations, then refresh the
stored snapshot and compare again. You may use the supplied `CREATE MATERIALIZED VIEW ... AS` and
`REFRESH MATERIALIZED VIEW` syntax scaffold. Separate the authoritative borrower fact from a derived report copy.

Choose a freshness policy for (a) a live lending desk and (b) a nightly summary. Explain the write/refresh work,
stale-read risk, and extra storage. Fewer joins is an observation about the query, not measured proof of faster reads.
See PostgreSQL's [materialized views](https://www.postgresql.org/docs/18/rules-materializedviews.html).

**Individual exit:** explain one rejected write, one still-unenforced rule, and one design change supported by your
SQL results. Save the extended draw.io diagram, SQL, and [`evidence.md`](../work/practice-04/evidence.md).
Practice 5 begins by revisiting this exit question.

## Further Investigations

The type choices, diagram, constraint tests, repairs, and report experiment above are core practice work.
For additional depth, compare a partial unique index for one open loan per copy with the separate problem of
historical interval overlap; compare natural and generated IDs under an import; or investigate case-insensitive
card codes. Each investigation needs reproducible inputs, results, an explanation, and a limitation.
These themes do not promise bonus points; any assessed bonus requires a separately published task and criteria.
