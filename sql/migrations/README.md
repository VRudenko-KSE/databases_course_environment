# PostgreSQL startup migrations

Compose mounts this directory at `/docker-entrypoint-initdb.d`. PostgreSQL runs the numbered `.sql` files in
filename order **only when its data volume is empty**:

1. `00-university.sql` defines and populates the university fixture for Practices 1–2.
2. `10-library-03-04.sql` creates the populated `library_lab` baseline for Practices 3–4.
3. `20-practices-05-06.sql` creates independent `library_p5` and `library_p6` fixtures.

Add later practice stages as higher-numbered files. Keep each stage deterministic and fail on SQL errors. Adding
or editing a file does not update an existing volume; `docker compose down -v` followed by
`docker compose up -d --wait` recreates all data and removes saved database edits and pgAdmin preferences. The
[Practice 3 prerequisite](../../docs/practices-03-04.md#fresh-start-prerequisite) documents the student route.
