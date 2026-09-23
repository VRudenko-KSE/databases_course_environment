# Query and script workflows

Run Compose commands from `course-environment`, the directory containing `compose.yaml`. PostgreSQL and `psql` run in the `db` container. The host's `work/` directory is mounted at `/work` in both containers. PostgreSQL receives it read only; pgAdmin can read and write it. Use `work/` for SQL, diagrams, notes, and exported files you want to keep on your computer.

The supplied pgAdmin registration is **Course PostgreSQL**. It connects to host `db`, port `5432`, database `university`, as database user `student`. pgAdmin's web login uses `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD` in `.env`; PostgreSQL uses `POSTGRES_PASSWORD`.

## Start and check the environment

Copy `.env.example` to `.env` once and choose passwords before the first startup. Then run:

```text
docker compose up -d --wait
docker compose ps
```

Both services should be healthy. With the default port, open `http://localhost:5050` on the same computer. In pgAdmin, open **Course → Course PostgreSQL → Databases → university → Query Tool**. Enter the database password if asked and run:

```sql
SELECT current_database() AS database_name, current_user AS user_name;
SELECT COUNT(*) AS course_count FROM practice.courses;
SELECT course_id FROM practice.courses ORDER BY course_id;
```

Expect `university | student`, count `8`, and IDs `101, 102, 103, 104, 105, 201, 202, 301`.

## Share files with pgAdmin

In pgAdmin's Query Tool, use **Open File** to load a `.sql` file or **Save As** to write one. In the file dialog, choose **Course work** under shared storage, then select the path below it, such as `practice-03/01-schema.sql`. The same file appears on your computer at `course-environment/work/practice-03/01-schema.sql`. pgAdmin's **Storage Manager** also shows **Course work**; use it to upload or download files. Save in the Query Tool before editing the same file locally, and reopen it after local edits so you do not overwrite newer work.

On Linux Docker Engine, pgAdmin runs inside the container as UID 5050. If pgAdmin says it cannot write to `work/`, grant that UID access **on the host** from `course-environment`, then restart the services:

```sh
sudo setfacl -R -m u:5050:rwX,u:$(id -u):rwX work
sudo find work -type d -exec setfacl -m d:u:5050:rwx,d:u:$(id -u):rwx {} +
```

Install the `acl` package if `setfacl` is unavailable. Your own account retains ownership; the access and default ACLs let both you and pgAdmin edit existing and newly created files. If a shared course server has several students, use each student's own copy of `course-environment` and `work/`; a single shared folder would expose everyone's files to the same pgAdmin login. Docker Desktop on Windows/macOS generally maps host files through its file sharing layer; check that `work/` is in a shared location if a save fails.

See pgAdmin's [shared storage setting](https://www.pgadmin.org/docs/pgadmin4/9.17/config_py.html)
and [container file permissions](https://www.pgadmin.org/docs/pgadmin4/9.17/container_deployment.html).

## Use interactive container psql

```text
docker compose exec db psql -X -U student -d university
```

At `university=#`, enter SQL ending in a semicolon. `\conninfo` shows the connection, `\dt practice.*` lists practice tables, and `\q` exits. For one query without entering the prompt:

```text
docker compose exec db psql -X -U student -d university -c "SELECT COUNT(*) FROM practice.courses;"
```

## Run your own saved SQL file

Create `work/my-first-query.sql` with your editor or pgAdmin:

```sql
SELECT 'Saved on my computer' AS message;
```

Save it, then run this from `course-environment` in PowerShell, Terminal, or a Linux shell:

```text
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/my-first-query.sql
```

Expect `Saved on my computer` and exit status `0` (`$LASTEXITCODE` in PowerShell, `echo $?` on macOS/Linux). Change the text to `Edited`, save, and run it again. The changed output confirms the container read the current host file. `-T` disables terminal allocation; `ON_ERROR_STOP=1` stops on a SQL error. Replace the filename for `work/practice-02.sql` or your Practice 3–4 files. The file path used by `psql` begins `/work/`, while the path in your local editor begins `work/`.

To test error stopping, put this in `work/intentional-error.sql`:

```sql
SELECT * FROM practice.no_such_table;
SELECT 'THIS MUST NOT RUN' AS sentinel;
```

Run it with the same command using `/work/intentional-error.sql`. It should report the missing table, exit nonzero, and not print the sentinel. Successful statements before a failure are not automatically undone; use `BEGIN` and `ROLLBACK` when needed. Delete the test file when finished.

## Stop and reset

`docker compose stop` and `docker compose start` preserve the named PostgreSQL and pgAdmin volumes and the host `work/` files. The scoped reset below rebuilds only the `practice` schema:

```text
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/reset-practice.sql
```

`docker compose down -v` removes this project's database and pgAdmin volumes. Files in host `work/` remain. Do not run machine-wide Docker cleanup commands on a shared server.
