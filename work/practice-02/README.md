# Practice 2 query examples

These worked examples use only `practice.courses`. They are separate from the prompt-only
[`practice-02.sql`](../practice-02.sql), so that starter can remain unanswered before class.

## Reading order

Use these core examples during the main session:

1. [Select columns and aliases](01-select-aliases.sql)
2. [Filter with comparisons](02-where-comparisons.sql)
3. [Group `AND` and `OR` conditions](03-and-or-parentheses.sql)
4. [Order tied values predictably](04-order-by-ties.sql)
5. [Limit a deterministically ordered result](05-limit-deterministic.sql)

The remaining predicates are optional if time allows:

- [Use inclusive `BETWEEN` endpoints](06-between-inclusive.sql)
- [Match a set with `IN`](07-in-list.sql)
- [Match a text pattern with `LIKE`](08-like-pattern.sql)
- [Recognize a successful empty result](09-empty-result.sql)

To use an example in pgAdmin, open the file, copy its SQL into the Query Tool connected to the
`university` database, and execute it. The expected rows in each file assume the supplied seed is unchanged.

To run a saved example with Docker, change to `course-environment` and use this command. It works unchanged in
PowerShell and macOS/Linux shells:

```sh
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/practice-02/01-select-aliases.sql
```

Change only the final filename to run another example. Every file is read-only and contains one `SELECT`.
