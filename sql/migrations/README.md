# PostgreSQL startup migrations

Compose mounts this directory at `/docker-entrypoint-initdb.d`. PostgreSQL runs the numbered `.sql` files in
filename order **only when its data volume is empty**:

1. `00-university.sql` defines and populates the university fixture for Practices 1–2.
2. `10-library-03-04.sql` creates the populated `library_lab` baseline for Practices 3–4.
3. `20-practices-05-06.sql` creates independent `library_p5` and `library_p6` fixtures.
4. `30-practices-07-08.sql` creates unindexed storage tables/location views in `storage_lab`, retained for
   optional storage/lecture exploration after the P7 redesign. P9/P10 core tasks use migration 60 instead.
5. `40-practices-07-08-reporting.sql` creates the P8 fictional window results in `reporting_lab`, plus legacy
   teacher-link examples; canonical university grades remain unchanged.
6. `50-practice-07-activity.sql` adds the independent P7 students/workshops/associations/status-event fixture
   in `activity_lab`: 7 students, 4 workshops, 10 associations and 18 events. UTC boundaries, a quiet day,
   tied latest events and an active August-only registration support the report checks.
7. `60-practices-09-10.sql` adds `index_lab`: 100,000 students, 500 courses, 10,000 offerings,
   2,000,000 enrolments and a 1,000-row scratch-write batch. It supplies constraint indexes, rare/common statuses,
   missing grades, grade/timestamp ties, explicit UTC boundaries, an empty offering and a quiet date.
8. `70-practices-11-12.sql` adds independent `advanced_lab` students, programmes, requirements, attempts,
   rooms, bookings and portal events. Repeated/NULL attempts, empty requirements, adjacent bookings,
   equal timestamps, session boundaries and missing dates support the advanced SQL/index experiments.
9. `71-practices-11-12-edge-cases.sql` safely upgrades three background rows: mixed passing/failing
   required-course attempts, a pass outside requirements, and a 30.5-minute event gap. Totals stay unchanged.
   It accepts only exact old/current target tuples, refuses unexpected edits atomically and is safe to reapply.
10. `80-p13-atomicity.sql`, `83-p13-locking.sql`, `84-p14-visibility.sql`,
    `86-p14-serializable.sql` and `88-p13-cte.sql` install the five current transaction fixtures:
    `p13_atomicity`, `p13_locking`, `p14_visibility`, `p14_serializable` and `p13_cte`.
    Each creates only its own schema. The CTE fixture shares no state with the atomicity fixture.
    Gaps in numbering preserve the retained migration names; superseded replay fixtures are removed.

Add later practice stages as higher-numbered files. Keep each stage deterministic and fail on SQL errors. Adding
or editing a file does not update an existing volume; `docker compose down -v` followed by
`docker compose up -d --wait` recreates all data and removes saved database edits and pgAdmin preferences. The
[Practice 3 prerequisite](../../docs/practices-03-04.md#fresh-start-prerequisite) documents the student route.

For an existing database, [Practices 7–8](../../docs/practices-07-08.md#prepare-the-fixture) document applying
only the missing migrations once: 40 for `reporting_lab`, 50 for `activity_lab`. Existing P7–8 installations
normally need only 50. Their scoped checkpoint replaces activity_lab/reporting_lab and preserves storage_lab
plus earlier schemas. P9/P10 use the new index_lab fixture; storage_lab is a retained optional storage demonstration.
For existing installations, apply only missing migration 60 as described in the
[P9/P10 handout](../../docs/practices-09-10.md#prepare-before-practice-9).
Its full checkpoint replaces only index_lab/index_write; its index reset preserves the seed and constraint indexes.

For Practices 11–12, apply missing migration 70, then run migration 71 even when the fixture already exists,
as described in the [P11/P12 handout](../../docs/practices-11-12.md).
The scoped `sql/practices-11-12-ready.sql` checks counts and revised cases independently of earlier labs.
If 71 refuses, save work and inspect the target rows with the TA; interactive psql needs `ROLLBACK;`.
Its checkpoint replaces only `advanced_lab`, replaying 70 then 71;
the index reset removes experimental indexes there while preserving rows and constraint indexes.
Neither route resets earlier labs or host work files.

For Practices 13–14, use the [mini-lab preparation table](../../docs/practices-13-14.md#prepare-only-the-core-fixtures).
The five current migrations are 80, 88, 83, 84 and 86. No extra replay schemas are installed.
Install only an absent schema's migration; duplicate installation refuses instead of overwriting data.
Each ordinary-SQL `sql/mini-labs/<schema>-ready.sql` checks canonical structure and starting rows.
Rows changed by an exercise are expected: reset that lab before another replay or initial-state check.
Per-lab resets refuse unexpected structure, dependent views/external foreign keys and held locks;
they preserve other labs and files. Explicit TA-assisted rebuilds use RESTRICT with no cascade.
Run ROLLBACK after an interactive refusal and inspect the cause before retrying. Do not remove a
whole course volume to recover a mini-lab. End open A/B transactions before pausing or resetting.
Removing obsolete migration files does not drop schemas from existing databases; no cleanup migration is required.

An existing earlier activity fixture with 9 associations and 17 events will not receive the August-only
case when the package files change. Save lab edits, then use the documented scoped P7–8 checkpoint to
restore the current baseline; do not rerun migration 50 over an existing schema.
