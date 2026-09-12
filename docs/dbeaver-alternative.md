# Optional DBeaver Community alternative

pgAdmin in Docker is the main course GUI. DBeaver Community is an optional locally installed desktop application.
It connects to the same PostgreSQL container through the loopback host port. You still must start PostgreSQL with
Docker Compose, and you must not install PostgreSQL or a local `psql` client for DBeaver.

## Version and evidence

The [DBeaver Community download page](https://dbeaver.io/download/) and
[installation guide](https://dbeaver.com/docs/dbeaver/Installation/) were checked on **2026-09-12**. The current
Community release was **26.2.0**, with Windows x64/Arm, macOS Apple Silicon/Intel, and Linux x86/Arm downloads. Use
the current Community installer for your architecture if the version has advanced.

DBeaver installation, its first JDBC-driver download, and its GUI query path were not exercised on the available
host and remain **pending release evidence**. No screenshot is linked because a real capture from the tested release
is not available. The connection values below come from the tested Compose contract; pgAdmin and container `psql`
have already returned the stated identity.

## Install DBeaver Community

### Action 1: Confirm the course database is running

Where: PowerShell on Windows or Terminal on macOS/Linux, inside the `course-environment` directory. Type:

   ```text
   docker compose up -d --wait
   docker compose ps
   ```

Expected: `db` and `pgadmin` show `healthy`. Recovery: complete the matching
[Windows](setup-windows.md), [macOS](setup-macos.md), or [Linux](setup-linux.md) setup guide first.

### Action 2: Download DBeaver Community for the correct system

Where: a browser at the [official Community download page](https://dbeaver.io/download/). Select **Community**, not a
PRO trial, and use one branch below. Expected: one installer package in Downloads. Recovery: verify the architecture
in the OS setup guide before choosing x64/x86, Arm, Apple Silicon, or Intel.

- **Windows:** choose the x86 **EXE** for ordinary Intel/AMD Windows or the ARM **EXE** for Windows Arm. Run the
  executable, follow the installer prompts, and start **DBeaver Community** from the Start menu. The installer
  includes its own OpenJDK; a separate Java installation is unnecessary.
- **macOS:** choose **Apple Silicon DMG** for an M-series Mac or **Intel DMG** for an Intel Mac. Open the DMG,
  drag DBeaver to **Applications**, and start it from Applications. Approve the normal macOS prompt for the
  downloaded application.
- **Ubuntu or Debian:** choose the DEB for x86 or ARM, matching `uname -m`. In Terminal, change to Downloads and
  type `sudo apt install ./dbeaver-ce-*-linux-*.deb`. Start **DBeaver Community** from the application
  menu. Keep only one
  matching DBeaver DEB in that folder so the wildcard selects one file.
- **Fedora:** choose the RPM for x86 or ARM, matching `uname -m`. In Terminal, change to Downloads and type
  `sudo dnf install ./dbeaver-ce-*.rpm`. Start **DBeaver Community** from the application menu. Keep only one
  matching DBeaver RPM in that folder so the wildcard selects one file.

### Action 3: Complete the first-launch prompts

Where: DBeaver. Choose a workspace location under your user profile if asked and close any sample-database offer.
Expected: the main window shows **Database Navigator**. Recovery: use the default workspace if you are unsure; the
course connection does not require importing a project.

## Create and verify the course connection

### Action 4: Read the connection values from `.env`

Where: open `course-environment/.env` in a text editor. Record `POSTGRES_PORT` and `POSTGRES_PASSWORD`. Expected with
unchanged defaults: port `5432` and password `course-local-password`. Recovery: do not use `PGADMIN_PORT` or
`PGADMIN_DEFAULT_PASSWORD`; those belong to the browser application.

### Action 5: Open the PostgreSQL connection wizard

Where: DBeaver. Choose **Database → New Database Connection**, select **PostgreSQL**, and choose **Next**. Expected:
the PostgreSQL Main connection-settings page opens. Recovery: type `PostgreSQL` in the wizard's search box.

### Action 6: Download the PostgreSQL JDBC driver when DBeaver asks

Where: the DBeaver driver-download dialog that appears on first use. Review the listed PostgreSQL driver files,
choose **Download**, and wait until every file completes. Expected: DBeaver returns to the connection settings
without a missing-driver warning. Recovery: this download needs internet access. Retry on the course network or
configure the institution's proxy in DBeaver. Do not solve this by installing PostgreSQL, `psql`, or a native
PostgreSQL client.

### Action 7: Enter the course connection fields

Where: DBeaver's **Main** tab. Choose **Host** rather than URL and enter:

   <!-- rumdl-disable MD013 -->

   | Field | Value | Reason |
   |---|---|---|
   | Host | `localhost` | DBeaver runs on the host and reaches Docker's loopback-bound port. Do not enter `db`; that name exists only inside Compose. |
   | Port | `POSTGRES_PORT` from `.env`, normally `5432` | This is the published database port, not pgAdmin's web port. |
   | Database | `university` | Course database name. |
   | Authentication | **Username/password** | Course authentication method. |
   | Username | `student` | Course database user. |
   | Password | `POSTGRES_PASSWORD` from `.env` | Database password; it is separate from `PGADMIN_DEFAULT_PASSWORD`. |
   | Local Client | Leave unset/default | DBeaver uses JDBC; no local PostgreSQL tools are required. |

   <!-- rumdl-enable MD013 -->

   Expected: the generated connection points to `localhost:<POSTGRES_PORT>/university`. Recovery: compare each field
   with the table; leave SSH, proxy, and SSL settings at their defaults for this loopback-only course connection.

### Action 8: Test and save the connection

Where: the same DBeaver dialog. Choose **Test Connection**. If DBeaver asks to download the driver now, complete
action 6, then test again. Expected: a success dialog identifies PostgreSQL. Close it and choose **Finish**.
Recovery: confirm `docker compose ps` shows `db` healthy, use the port and database password from `.env`, and see
[Wrong database, user, or password](troubleshooting.md#wrong-database-user-or-password).

### Action 9: Run the same identity query

Where: right-click the saved course connection in **Database Navigator**, choose
**SQL Editor → New SQL Script**, paste the query, and use **Execute SQL Statement**:

   ```sql
   SELECT current_database() AS database_name, current_user AS user_name;
   ```

   Expected: one row contains `university` and `student`. Recovery: ensure the editor is attached to the course
   connection, reconnect, and run the query again.

### Action 10: Compare the required route

Where: the host terminal in `course-environment`. Run the same query with container `psql` using the command in
[Query and script workflows](query-and-script-workflows.md#use-a-one-off-query). Expected: DBeaver and container
`psql` report the same database and user. Recovery: treat any mismatch as the wrong DBeaver connection rather than
changing the course containers.
