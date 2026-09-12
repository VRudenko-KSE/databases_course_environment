# macOS setup from zero

Use this guide on a Mac. PostgreSQL, pgAdmin, and `psql` all run in Docker; do not install PostgreSQL or Homebrew
`libpq`. The commands below run in **Terminal**.

## Supported systems and evidence

The vendor pages were checked on **2026-09-12**. Docker Desktop supports the current and two previous major macOS
releases and requires at least 4 GB of RAM. It provides separate
[Apple Silicon and Intel downloads](https://docs.docker.com/desktop/setup/install/mac-install/). Check that page
again before installing because the supported macOS window moves with each major release.

Git's official page listed source release 2.55.0 when checked. Apple supplies Git through Xcode Command Line Tools;
the [official Git macOS page](https://git-scm.com/install/mac) identifies `xcode-select --install` as the installation
route used here.

The course runtime was exercised on **2026-09-12** on Darwin 25.6.0 x86_64 with Docker Desktop 4.55.0, Docker
client/engine 29.1.3, Compose v2.40.3-desktop.1, and a Linux amd64 engine. This proves the already-installed Intel
runtime and query path. A fresh Docker installer walkthrough, Apple Silicon runtime, screenshots of current
installer choices, and a novice walkthrough remain **pending release evidence**. No unobserved screenshot is linked.

## Install and start the environment

Phase links: [OS and virtualization preflight](#macos-preflight),
[install Git and Docker](#macos-install-git-and-docker),
[clone, configure, and start](#macos-clone-configure-and-start),
[pgAdmin and container queries](#macos-pgadmin-and-container-queries),
[saved SQL files](#macos-saved-sql-files), and [restart](#macos-restart).

<!-- rumdl-disable MD029 -->

### macOS preflight

1. **Identify the Mac and supported release.** Where: choose **Apple menu → About This Mac**. Record the macOS
   version and whether **Chip** says Apple M-series or **Processor** says Intel. Expected: the release is within
   Docker's current three-major-version window. Recovery: update macOS or use a supported course computer if it is
   outside that window.

2. **Open Terminal and check virtualization.** Where: **Finder → Applications → Utilities → Terminal**. Type:

   ```sh
   uname -m
   sysctl kern.hv_support
   ```

   Expected: `uname -m` prints `arm64` on Apple Silicon or `x86_64` on Intel, and the second command prints
   `kern.hv_support: 1`. Recovery: if it prints `0`, the Mac cannot run Docker Desktop with Apple's Hypervisor
   framework; use a supported course computer.

### macOS install Git and Docker

3. **Install Git.** Where: Terminal. First type `git --version`. If it prints a version, continue to action 4. If

   macOS offers to install developer tools, choose **Install**, accept the license, wait for completion, and choose
   **Done**. If no prompt appears, type:

   ```sh
   xcode-select --install
   ```

   Complete the same installer dialog, reopen Terminal, then type:

   ```sh
   command -v git
   git --version
   ```

   Expected: a Git path and version appear. Recovery: if `xcode-select` reports that tools are already installed but
   Git is missing, update macOS and ask the course team before installing another package manager.

4. **Download the matching Docker Desktop installer.** Where: open the

   [official Docker Desktop Mac page](https://docs.docker.com/desktop/setup/install/mac-install/) in a browser.
   Choose **Mac with Apple silicon** when action 1 showed an Apple chip, or **Mac with Intel chip** for Intel. Open
   `Docker.dmg`, drag the Docker icon to **Applications**, keep the installer disk image mounted until copying
   finishes, then eject it. Expected: `/Applications/Docker.app` exists. Recovery: delete only the incomplete app
   copy and repeat with the installer for the correct architecture.

5. **Start Docker Desktop.** Where: **Finder → Applications → Docker**. Read and, if acceptable, choose **Accept**
   for the subscription agreement. Choose **Use recommended settings**, enter the macOS password if requested,
   choose **Finish**, and wait until Docker reports that the engine is running. Expected: the Docker dashboard opens
   without an engine error. Recovery: approve any macOS security prompt for the official Docker application and
   reopen it; use [Troubleshooting](troubleshooting.md) if the engine remains stopped.

6. **Verify Docker in a fresh Terminal window.** Where: close Terminal, open it again, and type:

   ```sh
   command -v docker
   docker version
   docker compose version
   echo $?
   ```

   Expected: a Docker path, client/engine information, a Compose v2 version, and status `0`. Recovery: reopen Docker
   Desktop and wait for the engine. If `command -v docker` prints nothing, restart Terminal; if it remains missing,
   rerun Docker's setup and choose the recommended CLI configuration.

### macOS clone configure and start

7. **Obtain the course package.** Where: Terminal. The release announcement will provide the real URL. Replace the

   placeholder before running:

   ```sh
   cd "$HOME/Documents"
   COURSE_REPOSITORY_URL='PASTE_THE_URL_FROM_THE_RELEASE_ANNOUNCEMENT_HERE'
   git clone "$COURSE_REPOSITORY_URL" course-environment
   ```

   Expected: a new `course-environment` directory. Recovery: do not run the placeholder literally. For network,
   authentication, or repository errors, use
   [Failed clone](troubleshooting.md#failed-clone-or-no-release-url). If the instructor supplied a downloaded
   `course-environment` folder, move it into Documents with Finder and skip the clone command.

8. **Enter the package and confirm the working directory.** Where: Terminal. Type:

   ```sh
   cd "$HOME/Documents/course-environment"
   ls compose.yaml .env.example work/verify.sql
   ```

   Adjust the first path if you used another parent folder. Expected: all three paths are printed. Recovery: type
   `pwd` and `ls`, then enter the folder that contains `compose.yaml`.

9. **Create the local configuration once.** Where: Terminal in `course-environment`. Type:

   ```sh
   cp .env.example .env
   open -e .env
   ```

   Keep `POSTGRES_DB=university` and `POSTGRES_USER=student`. You may change the two passwords and the loopback host
   ports before first startup; save and close TextEdit. Expected: `ls -la .env` lists the file. Recovery: if `.env`
   already exists, do not overwrite it unless you mean to replace the local settings.

10. **Start PostgreSQL and pgAdmin.** Where: Terminal in `course-environment`. Type:

    ```sh
    docker compose up -d --wait
    docker compose ps
    echo $?
    ```

    The first start downloads the pinned images and may take several minutes. Expected: `db` and `pgadmin` show
    `healthy`, and the status is `0`. Recovery: keep Docker Desktop running. If a service is unhealthy, run
    `docker compose logs --tail 100` and use [Troubleshooting](troubleshooting.md). Never run a machine-wide Docker
    cleanup command.

### macOS pgAdmin and container queries

11. **Open the pre-registered pgAdmin connection.** Where: a browser. Open `http://localhost:5050`, or replace
    `5050` with `PGADMIN_PORT` from `.env`. Sign in with `PGADMIN_DEFAULT_EMAIL` and
    `PGADMIN_DEFAULT_PASSWORD`. Open **Course → Course PostgreSQL** and enter `POSTGRES_PASSWORD` if prompted.
    Expected: the supplied server expands without manual registration. Recovery: keep the web-app and database
    passwords distinct and confirm `pgadmin` is healthy.

12. **Run the identity query in pgAdmin.** Where: under **Course PostgreSQL**, expand **Databases**, right-click
    **university**, choose **Query Tool**, paste the SQL below, and press **F5** or the Execute button:

    ```sql
    SELECT current_database() AS database_name, current_user AS user_name;
    ```

    Expected: one row containing `university` and `student`. Recovery: reconnect to **Course PostgreSQL** with
    `POSTGRES_PASSWORD` from `.env`.

13. **Use interactive container `psql`.** Where: Terminal in `course-environment`. Type:

    ```sh
    docker compose exec db psql -X -U student -d university
    ```

    Expected: `university=#`. Type the identity query, including the semicolon, then type `\q` on its own line.
    Recovery: if Compose cannot find its file, return to action 8. Do not install a local `psql`.

14. **Run a one-off query and inspect its status.** Where: Terminal in `course-environment`. Type:

    ```sh
    docker compose exec db psql -X -U student -d university -c \
      'SELECT current_database() AS database_name, current_user AS user_name;'
    echo $?
    ```

    Expected: `university | student` and status `0`. Recovery: the backslash must be the final character on the
    first line; otherwise put the Docker command on one line.

### macOS saved SQL files

15. **Run a host SQL file through the mount.** Where: Terminal in `course-environment`. Type:

    ```sh
    ls -l work/verify.sql
    docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/verify.sql
    echo $?
    ```

    Expected: identity `university | student`, count `8`, IDs `101, 102, 103, 104, 105, 201, 202, 301`, and status
    `0`. The local `work/verify.sql` is exposed read-only inside `db` as `/work/verify.sql`. Recovery: save new SQL
    files under the local `work` directory, then rerun the command with the matching `/work/...` name. See
    [Missing or unreadable bind-mounted SQL](troubleshooting.md#missing-or-unreadable-bind-mounted-sql).

### macOS restart

16. **Stop and start while preserving state.** Where: Terminal in `course-environment`. Type:

    ```sh
    docker compose stop
    docker compose start
    docker compose ps
    ```

    Expected: both services stop and return; database, pgAdmin state, and host `work` files remain. Use
    `docker compose restart` for a direct restart. Recovery: use `docker compose up -d --wait` if `start` says the
    containers do not exist.

17. **Finish the readiness check.** Where: Terminal and the browser. Confirm both services are healthy, pgAdmin and
    container `psql` return the same identity, and the saved script status is `0`. Recovery: record the command,
    `echo $?`, and error text before following [Troubleshooting](troubleshooting.md). Do not delete named volumes
    unless the stale-credentials recovery fits and you accept losing local database state.

<!-- rumdl-enable MD029 -->

Continue with [Query and script workflows](query-and-script-workflows.md). DBeaver is an
[optional local alternative](dbeaver-alternative.md); pgAdmin remains the main course GUI.
