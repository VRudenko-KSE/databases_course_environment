# Course PostgreSQL environment

This package supplies PostgreSQL, pgAdmin, and the course's starter university data through Docker Compose. Run
commands from this directory, which contains `compose.yaml`. PostgreSQL and `psql` run only inside Docker.

Start with the complete guide for your computer:

- [Windows setup from zero](docs/setup-windows.md)
- [macOS setup from zero](docs/setup-macos.md)
- [Ubuntu, Debian, or Fedora Docker Desktop setup from zero](docs/setup-linux.md)
- [Connect to the shared course instance](docs/connect-to-instance.md)
- [Connect from Windows with PuTTY](docs/connect-with-putty.md)
- [Install Docker Engine on Ubuntu from the terminal](docs/install-docker-ubuntu-cli.md)

Each guide installs Git and Docker Desktop, obtains this standalone package, starts the services, opens the supplied
pgAdmin connection, and checks container `psql` and a host-saved SQL file. Use
[Troubleshooting](docs/troubleshooting.md) when an expected result differs.

See the [practice dataset guide](docs/dataset.md) for the four-table fixture, its deliberate edge cases, and an
optional Week 4 `EXPLAIN (ANALYZE, BUFFERS)` sample.

For Practice 2, edit `work/practice-02.sql` and answer the `SELECT`, filtering, ordering, and limiting prompts from
class against `practice.courses`. Run the saved file through `/work` as shown in
[Query and script workflows](docs/query-and-script-workflows.md). Worked examples are separate private TA material.

For the next pair, use [Practices 3–4: Design, Build, and Improve a Library Database](docs/practices-03-04.md).
It includes draw.io instructions, student SQL files, and separate empty/populated recovery checkpoints in the
disposable `library_lab` schema. Both sessions use the full 80 minutes for demonstrations and exercises.

The host `work/` directory is shared with pgAdmin as **Course work** and with PostgreSQL as `/work` (read only in
the database container). Save SQL in `work/` using your local editor or pgAdmin's file dialog, then run it through
container `psql`. On Linux, grant pgAdmin's container user (UID 5050) write access to `work/` before saving from
pgAdmin; see [Query and script workflows](docs/query-and-script-workflows.md#share-files-with-pgadmin).

1. Copy `.env.example` to `.env` and choose local ports/passwords before the first startup.
2. Run `docker compose up -d --wait`.
3. Open pgAdmin at `http://localhost:5050` (or your `PGADMIN_PORT`) and sign in with its pgAdmin email/password.
4. Use the pre-registered **Course PostgreSQL** server; enter the separate database password if prompted.

The default database connection is `university` as `student`. pgAdmin's email/password variables are
`PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD`; database authentication uses `POSTGRES_PASSWORD`.
For the shared VM, the instructor can set `POSTGRES_BIND_ADDRESS=0.0.0.0` and
`PGADMIN_BIND_ADDRESS=0.0.0.0` in its `.env` before starting Compose. This publishes the services on the VM's
public interface; change both sample passwords before exposing them. On a personal computer, the default
`127.0.0.1` binding keeps access local.

<!-- rumdl-disable MD013 -->

| What you need to do | Command or route | Expected result |
|---|---|---|
| Start and wait | `docker compose up -d --wait` | `db` and `pgadmin` become healthy |
| Check services | `docker compose ps` | Both services show their state |
| Interactive SQL | `docker compose exec db psql -X -U student -d university` | `university=#` prompt |
| One-off identity query | `docker compose exec db psql -X -U student -d university -c "SELECT current_database(), current_user;"` | `university`, `student` |
| Verify fixture | `docker compose exec db psql -X -U student -d university -c "SELECT COUNT(*) FROM practice.courses;"` | Count `8` |
| Reset practice schema | `docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/reset-practice.sql` | Original `practice` fixture restored |
| Stop services | `docker compose stop` | Volumes remain for the next start |
| Restart services | `docker compose restart` | Services restart; volumes remain |
| Full reset (destructive to service volumes) | `docker compose down -v`, then `docker compose up -d --wait` | Database and pgAdmin volumes recreated; host files outside Compose remain |

<!-- rumdl-enable MD013 -->

Read [Query and script workflows](docs/query-and-script-workflows.md) for pgAdmin, interactive `psql`, one-off
queries, saved files, expected output, error stopping, and platform-specific shell examples. pgAdmin is the main
course GUI; [DBeaver Community](docs/dbeaver-alternative.md) is an optional locally installed alternative. The
[release checklist](docs/release-checklist.md) distinguishes observed runtime evidence from platform checks that
remain pending.
