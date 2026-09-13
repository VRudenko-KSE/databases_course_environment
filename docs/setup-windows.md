# Windows setup from zero

Use this guide on a personal Windows computer. PostgreSQL, pgAdmin, and `psql` all run in Docker; do not install
PostgreSQL or a Windows `psql` package. Run the course commands in **PowerShell**, not Git Bash, Command Prompt, or
a WSL terminal.

## Supported systems and evidence

The vendor pages were checked on **2026-09-12**. Docker currently requires WSL 2.1.5 or later, hardware
virtualization, 8 GB of RAM, and a Windows release still in Microsoft's servicing period. Its current x86_64 matrix
names Windows 10 22H2 build 19045 and Windows 11 23H2 build 22631 or later. Check the
[current Docker Desktop Windows requirements](https://docs.docker.com/desktop/setup/install/windows-install/)
before downloading because this list changes. The Windows Arm build is Early Access and is not yet course-verified.

Git's official page offered Git 2.55.0 and Git for Windows 2.55.0(5) when checked. Use the current maintained
[x64 or Arm64 Git installer](https://git-scm.com/install/windows) that matches the computer.

The course runtime has been exercised on macOS with a Linux amd64 Docker engine, not on Windows. The Windows
installer screens, WSL restart path, bind mounts, native Windows runtime, Windows Arm runtime, and a novice
walkthrough are **pending release evidence**. No screenshot is linked because no real Windows installer capture is
available. The exact vendor menu and button names below are from the current official instructions.

## Install and start the environment

Phase links: [OS and virtualization preflight](#windows-preflight),
[install Git and Docker](#windows-install-git-and-docker),
[clone, configure, and start](#windows-clone-configure-and-start),
[pgAdmin and container queries](#windows-pgadmin-and-container-queries),
[saved SQL files](#windows-saved-sql-files), and [restart](#windows-restart).

<!-- rumdl-disable MD029 -->

### Windows preflight

1. **Check Windows, CPU, disk, access, and virtualization.** Where: press **Windows key + R**, type `winver`, and
   press **Enter**. Then open **Settings → System → About** and read **System type**: choose x64 installers for an
   x64-based Intel/AMD PC and Arm64 installers for an ARM-based PC. Open **File Explorer → This PC** and check the
   available space on the drive where Docker will store data (normally `C:`). Plan for **5 GB free** for this course;
   that is a course planning allowance, not a measured vendor requirement. Confirm that you can approve a **User
   Account Control** prompt or obtain administrator help for WSL and Docker. Finally open **Task Manager →
   Performance → CPU** and find **Virtualization**. Expected: the Windows build meets the current Docker matrix and
   Virtualization says **Enabled**. Recovery: if the build is unsupported, run Windows Update or use a supported
   course computer. If virtualization says **Disabled**, enable Intel VT-x or AMD-V in BIOS/UEFI using the computer
   manufacturer's instructions. A managed computer may require IT support. In every command block, copy only the
   command itself; do not copy a displayed `PS C:\...>` prompt.

2. **Install or update WSL 2.** Where: search for **PowerShell**, choose **Run as administrator**, and approve the

   User Account Control prompt. Type:

   ```powershell
   wsl --version
   ```

   Expected: version details appear and WSL is at least 2.1.5. If the command is missing, type `wsl --install`; if
   it is older, type `wsl --update`. Restart Windows whenever the command or Windows asks, sign back in, reopen
   administrative PowerShell, and run `wsl --version` again. Recovery: if an error mentions virtualization,
   `HCS_E_HYPERV_NOT_INSTALLED`, or `ERROR_NOT_SUPPORTED`, return to action 1 and see
   [Unsupported virtualization or WSL](troubleshooting.md#unsupported-virtualization-or-wsl).

### Windows install Git and Docker

3. **Install Git.** Where: in a web browser, open the

   [official Git for Windows page](https://git-scm.com/install/windows), choose the x64 installer for an Intel/AMD
   computer or Arm64 for a Windows Arm computer, and run the downloaded setup file. Keep the installer defaults,
   including the option that makes Git available from the command line, then choose **Install** and **Finish**.
   Close all PowerShell windows, open a new ordinary PowerShell window from the Start menu, and type:

   ```powershell
   Get-Command git
   git --version
   ```

   Expected: PowerShell shows the path to `git.exe` and a version. Recovery: if `Get-Command` says Git is not
   recognized, reopen PowerShell once; if it still fails, rerun the installer and enable Git from the command line.

4. **Download and install Docker Desktop.** Where: open the

   [official Docker Desktop Windows page](https://docs.docker.com/desktop/setup/install/windows-install/). Choose
   **Windows x86_64** for an Intel/AMD computer. Choose Windows Arm only if the course team has explicitly approved
   the current Early Access build. Run `Docker Desktop Installer.exe`, select the recommended **per-user** install,
   and choose **Use WSL 2 instead of Hyper-V** on the Configuration page when the choice is shown. Continue through
   the wizard and choose **Close**. Expected: **Docker Desktop** appears in the Start menu. Recovery: complete any
   restart requested by WSL or the installer before continuing. Do not switch to Windows containers; this package
   uses Linux containers.

5. **Start Docker Desktop.** Where: open **Docker Desktop** from the Start menu. Read and, if acceptable, choose
   **Accept** on the Docker Subscription Service Agreement. Wait until Docker Desktop reports that the engine is
   running. Expected: the dashboard opens without an engine error. Recovery: a pending reboot is common after WSL
   setup; restart Windows and try again. For a virtualization or access error, use the matching section in
   [Troubleshooting](troubleshooting.md).

6. **Verify Docker from a fresh PowerShell window.** Where: close PowerShell, open a new ordinary PowerShell window,

   and type:

   ```powershell
   Get-Command docker
   docker version
   docker compose version
   $LASTEXITCODE
   ```

   Expected: `Get-Command` shows `docker.exe`, both version commands show client information, and `$LASTEXITCODE`
   prints `0`. Recovery: if Docker is missing from PATH, reopen PowerShell or restart Windows. If the client exists
   but cannot connect to the daemon, start Docker Desktop and wait for the engine.

### Windows clone configure and start

7. **Obtain the course package.** Where: stay in PowerShell and change to the parent folder where you want to keep

   course files, for example `Set-Location "$HOME\Documents"`. The release announcement will supply the real URL.
   Replace `<repository-url>`, including the brackets, with that actual URL before running:

   ```powershell
   git clone <repository-url> course-environment
   ```

   Expected: a new `course-environment` folder appears. Recovery: do not run the placeholder literally. For an
   authentication, network, or missing-repository error, see
   [Failed clone](troubleshooting.md#failed-clone-or-no-release-url). If the instructor supplied a downloaded
   `course-environment` folder instead, move it to Documents and skip the clone command.

8. **Enter the package and confirm the working directory.** Where: PowerShell. Type:

   ```powershell
   Set-Location "$HOME\Documents\course-environment"
   ```

   Adjust the first path if you chose another parent folder. Recovery: use `Set-Location` to enter the folder that
   contains `compose.yaml`.

9. **Create the local configuration once.** Where: PowerShell in `course-environment`. Type:

   ```powershell
   Copy-Item .env.example .env
   ```

   Open `.env` in your preferred text editor. Keep `POSTGRES_DB=university` and `POSTGRES_USER=student`. You may change
   the two passwords and the loopback host ports before the first start; save the file. Recovery: if
   `.env` already exists, do not overwrite it unless you intend to replace your local settings. Database and
   pgAdmin passwords are separate settings.

10. **Start PostgreSQL and pgAdmin.** Where: the same PowerShell window in `course-environment`. Type:

    ```powershell
    docker compose up -d --wait
    docker compose ps
    $LASTEXITCODE
    ```

    The first start downloads the pinned images and can take several minutes. Expected: `db` and `pgadmin` show
    `healthy`, and `$LASTEXITCODE` is `0`. Recovery: keep Docker Desktop open. If either service is not healthy, run
    `docker compose ps` and `docker compose logs --tail 100`, then use [Troubleshooting](troubleshooting.md). Do not
    run a machine-wide Docker cleanup command.

### Windows pgAdmin and container queries

11. **Open the pre-registered pgAdmin connection.** Where: a web browser. Open `http://localhost:5050`, or replace
    `5050` with `PGADMIN_PORT` from `.env`. Sign in with `PGADMIN_DEFAULT_EMAIL` and
    `PGADMIN_DEFAULT_PASSWORD` from `.env`. In the left tree, open
    **Course → Course PostgreSQL**. If prompted, enter `POSTGRES_PASSWORD`. Expected: the server expands
    without creating a new registration. Recovery: use the pgAdmin password only on the web sign-in and the
    PostgreSQL password only on the server prompt. If the page does not load, verify `pgadmin` is healthy and check
    the selected port.

12. **Run the identity query in pgAdmin.** Where: under **Course PostgreSQL**, expand **Databases**, right-click
    **university**, choose **Query Tool**, paste the following SQL, and press **F5** or choose the Execute button:

    ```sql
    SELECT current_database() AS database_name, current_user AS user_name;
    ```

    Expected: one row containing `university` and `student`. Recovery: verify the tree selection is
    **Course PostgreSQL** and use the database password from `POSTGRES_PASSWORD`.

13. **Use interactive container `psql`.** Where: PowerShell in `course-environment`. Type:

    ```powershell
    docker compose exec db psql -X -U student -d university
    ```

    Expected: the prompt changes to `university=#`. Type the identity query from action 12, including its semicolon,
    then type `\q` on a line by itself to return to PowerShell. Recovery: if Compose cannot find its file, return to
    action 8. Never install a local `psql`; this command uses the one inside `db`.

14. **Run a one-off query and read its status.** Where: PowerShell in `course-environment`. Type:

    ```powershell
    docker compose exec db psql -X -U student -d university -c `
      "SELECT current_database() AS database_name, current_user AS user_name;"
    $LASTEXITCODE
    ```

    Expected: the result is `university | student` and `$LASTEXITCODE` is `0`. Recovery: the backtick must be the
    final character on the first command line; otherwise put the whole Docker command on one line.

### Windows saved SQL files

15. **Create, save, and run your own Windows SQL file through the bind mount.** Where: PowerShell in
    `course-environment` and your preferred text editor.

    1. Make an ignored personal copy; this leaves the tracked `work\verify.sql` unchanged:

       ```powershell
       Copy-Item .\work\verify.sql .\work\my-first-query.sql
       ```

    2. Open `work\my-first-query.sql` in your preferred text editor. Keep it as plain text, replace all file text
       with this SQL, and save it in the package's `work` folder with the exact name `my-first-query.sql` and UTF-8
       encoding:

       ```sql
       SELECT 'Saved on my laptop' AS message;
       ```

    3. Return to PowerShell and run the saved host file through its container path:

       ```powershell
       docker compose exec -T db psql -X -U student -d university `
         -v ON_ERROR_STOP=1 -f /work/my-first-query.sql
       $LASTEXITCODE
       ```

       Expected: `Saved on my laptop` and status `0`.

    4. Return to the same document, change only `Saved` to `Edited`, save, and rerun the preceding Docker
       command. Expected: `Edited on my laptop`. This observable change confirms that the container used your newly
       saved host file.

    5. Run the unchanged supplied verification file:

       ```powershell
       docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/verify.sql
       $LASTEXITCODE
       ```

       Expected: identity `university | student`, count `8`, course IDs `101, 102, 103, 104, 105, 201, 202, 301`,
       and status `0`. The Windows folder `work` is mounted read-only as `/work` inside the container. Recovery: save
       future scripts inside the local `work` folder, make sure the filename ends in `.sql` rather than `.sql.txt`,
       and see [Missing or unreadable bind-mounted SQL](troubleshooting.md#missing-or-unreadable-bind-mounted-sql).

### Windows restart

16. **Stop and start without losing work.** Where: PowerShell in `course-environment`. Type:

    ```powershell
    docker compose stop
    docker compose start
    docker compose ps
    ```

    Expected: the first command stops both services; the next two bring them back with the database and pgAdmin
    state preserved. Use `docker compose restart` for a direct restart. Files under `work` remain on Windows in all
    cases. Recovery: use `docker compose up -d --wait` if `start` says the containers do not exist.

17. **Finish the readiness check.** Where: PowerShell and the browser. Confirm both services are healthy, pgAdmin
    returns the identity row, container `psql` returns the same row, and the saved script exits `0`. Expected: all
    four checks agree. Recovery: record the exact command, `$LASTEXITCODE`, and error text and follow
    [Troubleshooting](troubleshooting.md); do not delete volumes unless the stale-credentials entry explicitly fits
    your case and you accept losing the local database state.

<!-- rumdl-enable MD029 -->

For more SQL examples, continue with [Query and script workflows](query-and-script-workflows.md). DBeaver is an
[optional local alternative](dbeaver-alternative.md); pgAdmin remains the main course GUI.
