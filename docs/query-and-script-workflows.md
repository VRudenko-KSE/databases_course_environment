# Query and script workflows

Run every PostgreSQL command in this guide from the `course-environment` directory: the directory containing
`compose.yaml`. PostgreSQL and `psql` are supplied by Docker. Do not install a database server or `psql` on your
computer for this course.

The supplied server registration in pgAdmin is **Course PostgreSQL**. It connects inside the Compose network to
host `db`, port `5432`, database `university`, as user `student`. The pgAdmin login is a separate web-application
account: `student@course.local`. Its password is `PGADMIN_DEFAULT_PASSWORD`; the database password is
`POSTGRES_PASSWORD`. The passwords happen to have defaults in `.env.example`, but they are different settings.

## Start and check the environment

Copy `.env.example` to `.env` once, if you have not already done so. Keep the default database and user names;
you may choose local ports and passwords before first startup. When a PostgreSQL volume already exists, changing
`POSTGRES_DB`, `POSTGRES_USER`, or `POSTGRES_PASSWORD` in `.env` does not change the existing database account.
Use the full reset below only when you intend to discard local database data.

PowerShell:

```powershell
Copy-Item .env.example .env
docker compose up -d --wait
docker compose ps
```

macOS/Linux shell:

```sh
cp .env.example .env
docker compose up -d --wait
docker compose ps
```

Both `db` and `pgadmin` should show `healthy`. pgAdmin is available at `http://localhost:5050` with the default
port. If you selected another `PGADMIN_PORT`, use that port instead. Use the complete
[Windows](setup-windows.md), [macOS](setup-macos.md), or [Linux](setup-linux.md) setup guide for installation and
first launch.

## Run the same check in pgAdmin

These screenshots were captured from the tested pgAdmin 9.17 container on macOS during the local release
rehearsal: [login screen](images/pgadmin-login.png),
[preloaded Course PostgreSQL server](images/pgadmin-preloaded-server.png), and
[matching Query Tool result](images/pgadmin-query-result.png).

1. Open pgAdmin and sign in with `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD` from `.env`.
2. In the left tree, open **Course → Course PostgreSQL**. Enter `POSTGRES_PASSWORD` from `.env` if pgAdmin
   asks for the database password.
3. Under **Course PostgreSQL**, expand **Databases**, right-click **university**, choose **Query Tool**, paste the
   identity query below, and press F5 or the Execute button.

```sql
SELECT current_database() AS database_name, current_user AS user_name;
```

The result has one row: `university | student`. In the same Query Tool, you can run the other checks from
[`work/verify.sql`](../work/verify.sql). pgAdmin runs SQL through the same `student` database connection as the
container commands below.

## Optional DBeaver desktop client

pgAdmin is the course GUI. DBeaver Community is an optional locally installed alternative, not a prerequisite.
Follow the [DBeaver Community alternative](dbeaver-alternative.md) for installation and driver download. Create a
PostgreSQL connection to host `localhost`, the `POSTGRES_PORT` from `.env` (default `5432`), database
`university`, user `student`, and the database `POSTGRES_PASSWORD`. Do not use `db` as the DBeaver host: `db`
works only between Compose containers. Test the connection and run the identity query above.

## Use interactive container psql

Start an interactive SQL session:

```sh
docker compose exec db psql -X -U student -d university
```

The `-X` option prevents personal `psqlrc` settings from changing the class session. The normal prompt is
`university=#`; a continuation prompt is `university-#` until you finish a statement with `;`. At the prompt run:

```sql
SELECT current_database() AS database_name, current_user AS user_name;
```

Useful `psql` meta-commands begin with a backslash and do not need `;`:

```text
\conninfo
\dt
\q
```

`\conninfo` displays the active connection; its expected fields include database `university` and user `student`.
`\dt` lists tables visible on the search path and includes `courses` in schema `practice`. `\q` leaves `psql` and
returns you to PowerShell or your shell.

## Use a one-off query

For one statement, keep the SQL in the command. This is convenient for a quick check and avoids opening a prompt.

PowerShell:

```powershell
docker compose exec db psql -X -U student -d university -c `
  "SELECT current_database() AS database_name, current_user AS user_name;"
```

macOS/Linux shell:

```sh
docker compose exec db psql -X -U student -d university -c \
  'SELECT current_database() AS database_name, current_user AS user_name;'
```

Both print one row with `university` and `student`. The different quote marks protect the SQL from the respective
host shell; `psql` itself is running in the `db` container.

## Run a saved SQL file

`work/verify.sql` is a file on your laptop. Compose mounts the whole local `work` directory read-only at `/work`
inside the database container, so its container filename is `/work/verify.sql`. It is not `/work` on your laptop.

Run the supplied verification file with error stopping enabled:

```sh
docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/verify.sql
```

This command is identical in PowerShell and macOS/Linux shells. A checkout path containing spaces is safe because
Compose reads the current directory; change into it first rather than placing the host path in the command.

PowerShell example:

```powershell
Set-Location 'C:\Users\Ada\Documents\Database Course\course-environment'
docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/verify.sql
```

macOS/Linux example:

```sh
cd '/home/ada/Database Course/course-environment'
docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/verify.sql
```

Expected output contains these results, in order:

```text
 database_name | user_name
 university    | student

 course_count
 8

 course_id
 101
 102
 103
 104
 105
 201
 202
 301
```

To run your Practice 2 work after saving it, use the same route with `/work/practice-02.sql`:

```sh
docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/practice-02.sql
```

Save the file before running it. If the host file is absent, the container reports that `/work/verify.sql` or
`/work/practice-02.sql` does not exist and exits nonzero. If you create a new file after Compose started, save it
in the local `work` folder and rerun the command; bind mounts expose the saved file. A file accidentally named
`practice-02.sql.txt` is a different filename and will not be found as `/work/practice-02.sql`.

## See a script stop on an error

This is a controlled demonstration, not a learner default. Create a temporary local file such as
`work/intentional-error.sql` containing:

```sql
SELECT * FROM practice.no_such_table;
SELECT 'THIS MUST NOT RUN' AS sentinel;
```

Run it with the same saved-file command, changing only the filename:

```sh
docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/intentional-error.sql
```

`psql` reports the missing relation, exits with a nonzero status, and does not print `THIS MUST NOT RUN`.
Immediately inspect the command status with the shell that ran it:

```powershell
$LASTEXITCODE
```

```sh
echo $?
```

`ON_ERROR_STOP=1` stops later commands; it does not roll back work that an earlier statement already committed.
Use an explicit transaction (`BEGIN` ... `COMMIT` or `ROLLBACK`) when a group of changes must succeed or fail
together. Delete the temporary intentional-error file when the demonstration ends; it is not part of the supplied
learner files.

## Stop, restart, and reset

Run these commands from `course-environment`.

<!-- rumdl-disable MD013 -->

| Goal | Command | Effect on your saved `work/` files |
|---|---|---|
| Stop services | `docker compose stop` | Preserved |
| Start stopped services | `docker compose start` | Preserved |
| Restart services | `docker compose restart` | Preserved |
| Start and wait for health | `docker compose up -d --wait` | Preserved |
| Reset only practice data | `docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/reset-practice.sql` | Preserved |
| Full reset, clearly destructive | `docker compose down -v` then `docker compose up -d --wait` | Preserved, but all database and pgAdmin volumes are removed |

<!-- rumdl-enable MD013 -->

The practice reset drops and recreates only the database schema `practice` from the shipped seed. It keeps host
files in `work/`, pgAdmin settings, and other database schemas. The full reset deletes this Compose project's two
named volumes, so it removes database changes and pgAdmin login/registration state; it does not delete host files.
Do not use machine-wide Docker cleanup commands. If you changed the credentials after an earlier startup and cannot
log in, either restore the old values in `.env` or deliberately use the full reset.
