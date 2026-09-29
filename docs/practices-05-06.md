# Practices 5–6 — One Query at a Time

Complete the [Practice 3 fresh-start prerequisite](practices-03-04.md#fresh-start-prerequisite) first. The
numbered PostgreSQL migrations load all data automatically on a new database volume. Use `library_p5` for
Practice 5, `library_p6` for Practice 6, and `practice` for the university tables. Your earlier `library_lab`
work stays separate. Tasks P5-1, P5-2, P6-1, and P6-2 revisit the four Practice 4 topics.

For each numbered task, write **one query**, run it in your chosen SQL interface (pgAdmin, DBeaver, or PyCharm),
and save the SQL, result, and a short explanation. The optional tasks use the same rule. Save Practice 5
answers in [`work/practice-05.sql`](../work/practice-05.sql) and Practice 6 answers in
[`work/practice-06.sql`](../work/practice-06.sql). Save or export each result from your interface with its task
number; keep all three outputs from P6-2. Run the supplied P6-2 and P6-3 statements in that interface too.
No task needs an error-producing statement, explicit transaction, or isolation setting.

## Practice 5 tasks

Complete P5-1 to P5-4 in order. Try P5-5 and P5-6 if time allows. Each row asks for one student-written query.

<!-- rumdl-disable MD013 -->

| Practice | Optional | Number | Name | Instructions | Explain and save |
|---:|:---:|---|---|---|---|
| 5 | false | P5-1 | Copies and rules | Join `library_p5.copies` to `library_p5.books`. Return copy ID, book title, replacement cost, and retirement flag in copy-ID order. | Identify the zero-cost retired copy. Using the Practice 3 schema, explain why the cost rule allows zero and which table owns the retirement flag. |
| 5 | false | P5-2 | Co-authors | Start from `library_p5.books` and left join `book_authors` and `authors`. Return book ID, title, author name, and credit order, ordered by book ID and credit order. | Explain why book 10 has two rows and book 30 has a NULL author. State what the `(book_id, author_id)` key identifies. |
| 5 | false | P5-3 | Students without enrolments | Left join `practice.students` to `practice.enrolments`. Return student ID, name, offering ID, and grade, ordered by student and offering. | Predict and explain the rows for students 1 and 7. |
| 5 | false | P5-4 | Course report | Start from every `practice.courses` row and left join offerings and enrolments. Return course ID, title, enrolment count, graded count, and average recorded grade, ordered by course ID. Use the enrolment key for its count and `grade` for the graded count. | Explain courses 101, 104, 202, and 301; save an individual exit answer. |
| 5 | true | P5-5 | Autumn offering report | Join enrolments, offerings, and courses. For autumn 2025 offerings, return offering ID, course title, enrolment count, graded count, and average grade. Keep only offerings with at least two enrolments. | Explain the roles of `WHERE` and `HAVING`. |
| 5 | true | P5-6 | Repeated course enrolment | Join students, enrolments, offerings, and courses. Group by student and course; return student ID, name, course ID, title, and offering count only when that student joined more than one offering of the course. | Explain why those enrolment rows are distinct. |

<!-- rumdl-enable MD013 -->

## Practice 6 tasks

Complete P6-1 to P6-4 in order. Try P6-5 and P6-6 if time allows. Each row asks for one student-written query;
the P6-2 query is reused and P6-3 has a supplied comparison query. Use the
[supplied statements for P6-2 and P6-3](#supplied-statements-for-p6-2-and-p6-3) below.

<!-- rumdl-disable MD013 -->

| Practice | Optional | Number | Name | Instructions | Explain and save |
|---:|:---:|---|---|---|---|
| 6 | false | P6-1 | Repeated facts | Join `library_p6.mixed_credits` for book 10 to `library_p6.books` and `library_p6.authors` by their IDs. Return book ID, author ID, the title and name stored in `mixed_credits`, and the title and name stored in the separate tables. | Explain which facts are repeated and where each fact belongs. |
| 6 | false | P6-2 | Live and stored reports | Join `library_p6.loan_live` to `library_p6.loan_report` by loan ID. For borrower 1, return loan ID, live borrower name, and stored borrower name. Run the same query before the supplied update, after the update, and after the supplied refresh. | Save all three results and explain the changes. |
| 6 | false | P6-3 | Set semantics | The supplied query below lists student IDs from offerings 1001 and 1002 with `UNION ALL`. Write a query for the same two offerings using `UNION`. Run both and order their results by student ID. | Explain why their row counts differ. |
| 6 | false | P6-4 | Offering summary | Write one `offering_summary` CTE with one row per offering, retaining empty offerings with a left join. Return offering ID, enrolment count, graded count, and average recorded grade. In the outer query show only offerings 1001, 1007, and 1008. | Explain the NULL averages and a recorded zero grade; save an individual exit answer. |
| 6 | true | P6-5 | Students without enrolments | Write one `EXCEPT` query returning the IDs of students who do not appear in `practice.enrolments`, ordered by student ID. | Explain why the result is one student. |
| 6 | true | P6-6 | Classify offering reports | Use a derived table that left joins offerings to enrolments and groups by offering. Return offering ID, enrolment count, graded count, raw average grade, display average, and status, ordered by offering ID. Use `COALESCE` to display zero only when the raw average is NULL. Use `CASE` to label rows `empty`, `ungraded`, `above overall`, or `at or below`, in that order of tests. Compare with the overall recorded-grade average through a scalar subquery. | Explain why the raw average remains visible beside the display average and what each query level computes. |

<!-- rumdl-enable MD013 -->

## Supplied statements for P6-2 and P6-3

For **P6-2**, run your comparison query first. Then run this supplied update and rerun your query. Save both
results. The update remains in the database.

```sql
UPDATE library_p6.borrowers
SET full_name = 'Olena Updated'
WHERE borrower_id = 1;
```

Finally, run this supplied refresh and rerun your same query. Save the third result.

```sql
REFRESH MATERIALIZED VIEW library_p6.loan_report;
```

For **P6-3**, run this supplied comparison query. Your own query changes the set operation while keeping the
same selected column, filters, and final ordering.

```sql
SELECT student_id FROM practice.enrolments WHERE offering_id = 1001
UNION ALL
SELECT student_id FROM practice.enrolments WHERE offering_id = 1002
ORDER BY student_id;
```

## Assignment 1 work

In Practice 5, show one model or report artefact, record one precise correction, and note your next action. In
Practice 6, inspect the required evidence, resolve one verification gap, and record the next action. The TA
will present a student solution or another solution after each exercise. Compare its row meaning, join keys,
NULL handling, and ordering with your saved answer.
