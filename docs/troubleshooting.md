# Troubleshooting the course environment

Run diagnosis and recovery commands from the `course-environment` directory unless a section says otherwise. Keep
the exact error text and shell status when asking for help. PostgreSQL and `psql` belong inside Docker; installing a
host PostgreSQL package does not repair this environment.

Start with these non-destructive checks:

```text
docker version
docker compose version
docker compose ps
docker compose logs --tail 100
```

Use `Get-Location` and `$LASTEXITCODE` in PowerShell, or `pwd` and `echo $?` on macOS/Linux, to record the working
directory and status. Never run `docker system prune`, `docker volume prune`, or another machine-wide cleanup for a
course problem.

## Docker is stopped

**Symptom:** `docker version` shows client details followed by “cannot connect to the Docker daemon,” “Docker Desktop
is not running,” or a named-pipe/socket error. Compose cannot start either service.

**Diagnose:** on Windows or macOS, open Docker Desktop and inspect its engine status. On Linux, run
`sudo systemctl status docker --no-pager`.

**Recover:** start Docker Desktop and wait for the engine, or run `sudo systemctl start docker` on Linux. Return to
the course directory and run `docker compose up -d --wait`, then `docker compose ps`.

**Expected:** `docker version` shows both Client and Server sections and both course services become healthy. If the
engine immediately stops again, continue with the virtualization or pending-reboot section.

## Unsupported virtualization or WSL

**Symptom:** Docker Desktop refuses to start. Windows may report `HCS_E_HYPERV_NOT_INSTALLED`,
`ERROR_NOT_SUPPORTED`, or an unexpected WSL error. A Mac may report an incompatible CPU.

**Diagnose on Windows:** open **Task Manager → Performance → CPU** and confirm **Virtualization: Enabled**. In
administrative PowerShell, run `wsl --version` and `wsl -l -v`. The current Docker requirements call for WSL 2.1.5
or later, supported Windows servicing, 8 GB of RAM, and hardware virtualization.

**Recover on Windows:** run `wsl --update`, or `wsl --install` if it is absent, and complete the requested restart.
Enable Intel VT-x or AMD-V in BIOS/UEFI using the computer maker's instructions. On a VM, the administrator must
enable nested virtualization. Do not guess firmware settings on a managed computer.

**Diagnose on macOS:** run `sysctl kern.hv_support`. A supported Mac prints `kern.hv_support: 1`.

**Recover on macOS:** confirm that the Docker installer matches Apple Silicon or Intel. A result of `0` means this
Mac cannot supply the required Hypervisor framework; use a supported course computer.

**Expected:** Docker Desktop reaches its running state and `docker version` shows a Server section. Windows and Mac
installer/firmware recoveries remain release-test items until observed on the named hardware.

## Linux Docker permission denied

**Symptom:** Docker exists, but commands report permission denied for `/var/run/docker.sock`.

**Diagnose:** run `id -nG`, `ls -l /var/run/docker.sock`, and `sudo systemctl status docker --no-pager`. The service
must be active and your login session must have the chosen access method.

**Recover:** on a personal course computer, follow the explicit access decision in
[Linux setup action 12](setup-linux.md#configure-access-and-start-the-course-package). If you accepted permanent
Docker-group access, run `sudo usermod -aG docker "$USER"`, then sign out of the desktop completely and sign back in.
Membership in `docker` grants root-level host privileges. On a managed computer, ask its administrator about
rootless or supervised access.

**Expected:** `id -nG` includes `docker` for the group route and `docker version` works without `sudo`. Do not change
socket permissions with `chmod 666`.

## A reboot or sign-out is still pending

**Symptom:** WSL, Docker, or Git was installed, but a new terminal still sees the old state. Docker may show WSL or
hypervisor errors immediately after Windows features were enabled. Linux still lacks new group membership.

**Diagnose:** note whether the installer or `wsl --install` requested a restart. On Linux, compare `groups` in the
current terminal after adding the user to `docker`.

**Recover:** save work. Restart Windows after WSL, Windows-feature, hypervisor, or Docker requests. On Linux, sign
out of the complete desktop session and sign back in; opening another terminal is insufficient. Reopen Docker
Desktop where applicable and wait for its engine.

**Expected:** `Get-Command docker` or `command -v docker` finds the CLI, and `docker version` shows Client and Server.

## Failed clone or no release URL

**Symptom:** `git clone` says repository not found, authentication failed, host could not be resolved, or the text
`PASTE_THE_URL_FROM_THE_RELEASE_ANNOUNCEMENT_HERE` appears in the error.

**Diagnose:** confirm that the course release announcement now contains a real repository URL and that you copied
the entire value into `COURSE_REPOSITORY_URL`. Run `git --version` separately. Do not invent a URL from the course
name.

**Recover:** reconnect to the network, sign in through the method named in the release announcement, and retry into
a parent directory that does not already contain `course-environment`. If no remote has been announced, use the
instructor-provided downloaded `course-environment` folder. A clean published-clone rehearsal remains a release gate.

**Expected:** the package directory contains `compose.yaml`, `.env.example`, `sql`, `pgadmin`, and `work`. If clone
failed after creating an incomplete folder, keep the error for support and choose a different empty destination for
the retry rather than deleting unrelated files.

## A host port is occupied

**Symptom:** startup reports “port is already allocated,” “address already in use,” or a bind error for `5432` or
`5050`. One service may be running while the other failed.

**Diagnose:** run `docker compose ps` and `docker compose logs --tail 100`. On Windows, **Resource Monitor → Network
→ Listening Ports** can identify the process. On macOS/Linux, `lsof -nP -iTCP:5432 -sTCP:LISTEN` and the same command
with `5050` show listeners when permitted. Do not terminate an unfamiliar process.

**Recover:** stop only this Compose project without deleting its volumes:

```text
docker compose down
```

Edit `.env`. Change `POSTGRES_PORT=5432` to an unused high port such as `15432`, or change
`PGADMIN_PORT=5050` to an unused port such as `15050`, matching the error. Then run:

```text
docker compose up -d --wait
docker compose ps
```

**Expected:** both services are healthy. Open pgAdmin with the new `PGADMIN_PORT`; DBeaver must use the new
`POSTGRES_PORT`. The Compose file still binds both ports to `127.0.0.1`.

## Changed `.env` credentials with an existing volume

**Symptom:** `.env` contains a new database or pgAdmin password, but the existing service rejects it. PostgreSQL and
pgAdmin use their initialization values when their named volumes are first created; editing `.env` later does not
rewrite stored accounts.

**Diagnose:** decide whether you need the database changes and pgAdmin settings already stored in this Compose
project. Check that you did not merely exchange `POSTGRES_PASSWORD` and `PGADMIN_DEFAULT_PASSWORD`.

**Recover while preserving state:** restore the previous values in `.env`, then run `docker compose up -d --wait`.

**Recover by deliberate reset:** only if you accept losing this course project's database changes and pgAdmin
settings, run:

```text
docker compose down -v
docker compose up -d --wait
```

This removes only the two named volumes belonging to this Compose project. Host files under `work` remain. Do not
use a machine-wide volume or system prune.

**Expected:** log in with the values used for the recreated volumes and rerun the identity query. A full reset is
destructive to container-held course state and cannot restore unsaved database changes.

## Git or Docker is missing from PATH

**Symptom:** PowerShell says a command is not recognized, or `command -v git` / `command -v docker` prints nothing.

**Diagnose:** open a completely new terminal after installation. On Windows use `Get-Command git` and
`Get-Command docker`; on macOS/Linux use `command -v git` and `command -v docker`.

**Recover:** for Git, rerun the OS guide's supported installer or package-manager action. For Docker Desktop, start
the application and complete its recommended CLI setup; then reopen the terminal. On Linux, install the official
`docker-ce-cli` and `docker-compose-plugin` packages from the correct distribution branch. Do not install a package
named `postgresql` or `psql`.

**Expected:** Git prints a version, Docker shows Client and Server, and `docker compose version` identifies Compose
v2. A Docker CLI path alone does not prove the engine is running.

## Wrong database, user, or password

**Symptom:** pgAdmin, DBeaver, or `psql` reports password authentication failed, a database does not exist, or the
identity query returns an unexpected name.

**Diagnose:** compare the client fields with `.env` and the fixed course identity:

- pgAdmin web sign-in: `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD`;
- database connection: database `university`, user `student`, and `POSTGRES_PASSWORD`;
- DBeaver host: `localhost` and `POSTGRES_PORT`;
- pgAdmin's pre-registered internal host: `db` and port `5432`.

**Recover:** correct only the client field that differs. If `.env` was changed after first startup, use the
[stale-credentials recovery](#changed-env-credentials-with-an-existing-volume). Do not change the supplied
`servers.json` or install local PostgreSQL tools.

**Expected:** this query returns exactly `university | student`:

```sql
SELECT current_database() AS database_name, current_user AS user_name;
```

## Course PostgreSQL registration is missing or deleted

**Symptom:** pgAdmin opens, but **Course → Course PostgreSQL** is absent because its registration was deleted or was
not loaded. Restarting pgAdmin does not recreate a registration that a learner deleted.

**Recover without resetting anything:** on pgAdmin's **Welcome** page, select the **Add New Server** quick link;
it opens the **Register - Server** form. You can also right-click **Servers** in the Browser tree and choose
**Register → Server…**. On **General**, enter **Name** `Course PostgreSQL` and, if you want the same organization,
set **Server group** to `Course`. On **Connection**, enter **Host name/address** `db`, **Port** `5432`,
**Maintenance database** `university`, **Username** `student`, and the database `POSTGRES_PASSWORD` from `.env`;
save the registration. The host is `db`, not `localhost`, because this registration connects from the pgAdmin
container across the Compose network. Then expand **Course → Course PostgreSQL → Databases**, open
**university → Query Tool**, and run:

```sql
SELECT current_database() AS database_name, current_user AS user_name;
```

**Expected:** the query returns `university | student`. This creates only one pgAdmin registration. It preserves the
PostgreSQL database, other pgAdmin preferences, and host files under `work`; do not use `docker compose down -v` for
this case.

## Wrong working directory

**Symptom:** Compose reports that no configuration file was found, or a relative file such as `.env.example` or
`work/verify.sql` is missing.

**Diagnose:** PowerShell: run `Get-Location` and `Get-ChildItem`. macOS/Linux: run `pwd` and `ls`. The current
directory must be the package directory containing `compose.yaml`.

**Recover:** use `Set-Location 'full\path\to\course-environment'` in PowerShell or
`cd '/full/path/to/course-environment'` on macOS/Linux. Quote a path that contains spaces. Then run
`docker compose ps` again.

**Expected:** the directory listing includes `compose.yaml`, `.env.example`, `sql`, `pgadmin`, and `work`.

## A script was saved as `.sql.txt`

**Symptom:** the editor shows `practice-02.sql`, but Docker reports `/work/practice-02.sql` does not exist. Windows
may be hiding known filename extensions.

**Diagnose:** in PowerShell run `Get-ChildItem .\work | Select-Object Name`; on macOS/Linux run `ls -la work`.

**Recover on Windows:** in File Explorer choose **View → Show → File name extensions**, then rename the file so its
complete name ends once with `.sql`. Confirm the rename warning. On macOS/Linux, rename the exact file, for example
`mv work/practice-02.sql.txt work/practice-02.sql`.

**Expected:** the host listing shows `practice-02.sql`, and the container command uses
`-f /work/practice-02.sql`.

## Missing or unreadable bind-mounted SQL

**Symptom:** `psql` reports that `/work/<name>.sql` does not exist or cannot be opened, or a service log reports
permission denied for a supplied bind mount.

**Diagnose:** first confirm the host file exists. PowerShell: `Get-Item .\work\<name>.sql`. macOS/Linux:
`ls -l work/<name>.sql`. Then list the container view:

```text
docker compose exec db ls -l /work
```

**Recover:** save the file under the package's host `work` directory and make the names match exactly, including
letter case on Linux. On macOS/Windows Docker Desktop, keep the checkout in a file-shared user folder. On Linux,
grant your user ordinary read access to the specific file; do not make the whole home directory world-writable. On
Fedora, use [Linux setup action 18](setup-linux.md#configure-access-and-start-the-course-package) only after an AVC
record confirms an SELinux denial on the three course-owned paths.

**Expected:** `docker compose exec db ls -l /work` shows the file, and this pattern exits `0`:

```text
docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/<name>.sql
```

Creating a file after the containers start does not require a restart; save it and rerun the command. The mount is
read-only inside the container, so edit files on the host.

## Verification status

The local candidate's macOS Intel rehearsal observed Docker stop/start recovery with database and pgAdmin state
preserved. It also observed a space-containing clean local clone, stop-on-error behavior, and occupied-port recovery
by changing project ports. The canonical evidence and remaining gates are in the
[release checklist](release-checklist.md#task-6-local-release-candidate-verification).

Windows/WSL, macOS fresh installation, native Linux, Fedora SELinux, Arm, DBeaver GUI/driver, and novice recovery
walkthroughs remain unverified release checks. The course release must not convert these instructions into claims
until the named platform and exact version have been observed.
