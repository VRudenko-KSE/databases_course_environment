# PostgreSQL startup migrations

Compose mounts this directory at `/docker-entrypoint-initdb.d`. PostgreSQL runs the numbered `.sql` files in
filename order **only when its data volume is empty**:

1. `00-university.sql` defines and populates the university fixture for Practices 1–2.
2. `10-library-03-04.sql` creates the populated `library_lab` baseline for Practices 3–4.
3. `20-practices-05-06.sql` creates independent `library_p5` and `library_p6` fixtures.
4. `30-practices-07-08.sql` creates unindexed storage tables/location views in `storage_lab`, retained for P9
   and optional lecture exploration after the P7 redesign.
5. `40-practices-07-08-reporting.sql` creates the P8 fictional window results in `reporting_lab`, plus legacy
   teacher-link examples; canonical university grades remain unchanged.
6. `50-practice-07-activity.sql` adds the independent P7 students/workshops/associations/status-event fixture
   in `activity_lab`: 7 students, 4 workshops, 10 associations and 18 events. UTC boundaries, a quiet day,
   tied latest events and an active August-only registration support the report checks.

Add later practice stages as higher-numbered files. Keep each stage deterministic and fail on SQL errors. Adding
or editing a file does not update an existing volume; `docker compose down -v` followed by
`docker compose up -d --wait` recreates all data and removes saved database edits and pgAdmin preferences. The
[Practice 3 prerequisite](../../docs/practices-03-04.md#fresh-start-prerequisite) documents the student route.

For an existing database, [Practices 7–8](../../docs/practices-07-08.md#prepare-the-fixture) document applying
only the missing migrations once: 40 for `reporting_lab`, 50 for `activity_lab`. Existing P7–8 installations
normally need only 50. Their scoped checkpoint replaces activity_lab/reporting_lab and preserves storage_lab
plus earlier schemas. Before P9, install migration 30 once if storage_lab is missing.

An existing earlier activity fixture with 9 associations and 17 events will not receive the August-only
case when the package files change. Save lab edits, then use the documented scoped P7–8 checkpoint to
restore the current baseline; do not rerun migration 50 over an existing schema.
