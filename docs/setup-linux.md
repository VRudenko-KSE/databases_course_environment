# Linux setup from zero

This guide installs Docker Desktop on supported Ubuntu, Debian, and Fedora desktop systems. PostgreSQL, pgAdmin,
and `psql` run in Docker; do not install PostgreSQL server or client packages. Commands run in the desktop's
**Terminal**.

## Supported systems and evidence

The vendor pages were checked on **2026-09-13**:

- [Docker Desktop for Linux](https://docs.docker.com/desktop/setup/install/linux/) supports only x86_64/amd64 Linux.
  It requires KVM, QEMU 5.2 or later, systemd, a supported desktop environment, and at least 4 GB of RAM. Docker
  does not support Docker Desktop for Linux inside a nested-virtualization environment.
- [Docker Desktop on Ubuntu](https://docs.docker.com/desktop/setup/install/linux/ubuntu/) currently lists Ubuntu
  26.04 and 24.04 on x86_64.
- [Docker Desktop on Debian](https://docs.docker.com/desktop/setup/install/linux/debian/) currently lists Debian 12
  on x86_64.
- [Docker Desktop on Fedora](https://docs.docker.com/desktop/setup/install/linux/fedora/) currently lists Fedora 43
  or later on x86_64.
- [Git's Linux page](https://git-scm.com/install/linux) uses each distribution's package manager.

The course images publish Linux amd64 and arm64 manifests, and macOS Apple Silicon remains a supported Docker
Desktop route, but Docker Desktop for Linux itself does not support Linux arm64. A student whose Linux machine
reports `aarch64` or `arm64`, or whose Linux VM relies on nested virtualization, must use a supported course machine;
do not replace this guide with a standalone Docker Engine installation. The course runtime has been exercised only
with Linux amd64 containers hosted by Docker Desktop on macOS. Native Docker Desktop execution on Ubuntu, Debian,
and Fedora, including KVM, context, file-sharing, fresh-installer, and novice-walkthrough checks, remains **pending**.
No installer screenshot is linked because no real Linux installation capture is available.

## Choose and install the distribution branch

Phase links: [OS and architecture preflight](#linux-preflight);
install Git and Docker Desktop on [Ubuntu](#ubuntu-install-git-and-docker),
[Debian](#debian-install-git-and-docker), or [Fedora](#fedora-install-git-and-docker);
then [clone, configure, and start](#linux-clone-configure-and-start),
[use pgAdmin and container queries](#linux-pgadmin-and-container-queries),
[run saved SQL files](#linux-saved-sql-files), and [restart](#linux-restart).

<!-- rumdl-disable MD029 -->

### Linux preflight

1. **Identify the distribution, CPU, disk, and access.** Where: open Terminal and type:

   ```sh
   cat /etc/os-release
   uname -m
   df -h "$HOME"
   ```

   Expected: the first command names a release in the supported list above. `x86_64` means amd64; `aarch64` means
   arm64. The last command must show at least **5 GB available** on the filesystem that holds your home folder and
   checkout; this is a course planning allowance, not a measured vendor requirement. Confirm that you can enter your
   login password for `sudo` or obtain administrator help before installing Docker. Recovery: do not paste commands
   from another branch. Update to a supported release or use a supported course computer if your release is absent.
   Derivatives such as Linux Mint and Kali are not covered by this guide. In every command block, copy only the
   command; do not copy a displayed prompt such as `student@host:~$`.

2. **Verify the Docker Desktop prerequisites before changing packages.** Where: Terminal. Type:

   ```sh
   uname -m
   free -h
   systemctl --version
   ls -l /dev/kvm
   ```

   Expected: `uname -m` prints `x86_64`, total memory is at least 4 GB, systemd is present, and `/dev/kvm` exists.
   Docker Desktop also requires QEMU 5.2 or later; the distribution package installed with Docker Desktop supplies
   or resolves that dependency, and action 12 verifies it. Use GNOME, KDE, or MATE as the desktop environment.
   Recovery: enable Intel VT-x or AMD-V in firmware with the computer owner's help if `/dev/kvm` is missing. If this
   Linux system is itself a virtual machine, ask the administrator whether it supplies supported KVM access; Docker
   Desktop does not support nested virtualization. If the CPU architecture or host cannot meet these requirements,
   use a supported course computer.

   If Docker Engine already exists, do not uninstall it or delete `/var/lib/docker`, images, containers, or volumes.
   Docker Desktop runs its own virtual machine, creates the `desktop-linux` context, and keeps its images and volumes
   separate from an existing host Engine. Existing Engine data does not migrate into Desktop.

### Ubuntu branch

#### Ubuntu install Git and Docker

3. **Install Git and Docker's repository prerequisites on Ubuntu.** Where: Terminal on Ubuntu 26.04 or 24.04. Type:

   ```sh
   sudo apt update
   sudo apt install ca-certificates curl git
   git --version
   ```

   Enter your login password when `sudo` asks; it does not display while typing. Expected: package installation
   completes and Git prints a version. Recovery: if `apt` reports a lock, let the system updater finish and retry.

4. **Add Docker's Ubuntu repository.** Where: the same Terminal. Paste the entire block exactly:

   ```sh
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
     -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
   Types: deb
   URIs: https://download.docker.com/linux/ubuntu
   Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
   Components: stable
   Architectures: $(dpkg --print-architecture)
   Signed-By: /etc/apt/keyrings/docker.asc
   EOF
   sudo apt update
   ```

   Expected: `apt update` includes `download.docker.com/linux/ubuntu` without a signature error. Recovery: confirm
   action 1 says Ubuntu and check the computer's clock and network; do not substitute the Debian repository.

5. **Download and install Docker Desktop on Ubuntu.** Where: open the
    [official Ubuntu Desktop page](https://docs.docker.com/desktop/setup/install/linux/ubuntu/) in a browser and use
   its **DEB package** download. In the file manager, open the directory that contains the download and choose
   **Open in Terminal**. Type:

   ```sh
   pwd
   ls -l docker-desktop-amd64.deb
   sudo apt update
   sudo apt install ./docker-desktop-amd64.deb
   ```

   Expected: `pwd` names the actual download directory, `ls` finds the package, and `apt` installs Docker Desktop
   plus its required CLI and Compose dependencies. If the browser localized the download directory or renamed the
   package, enter that directory and use the exact saved filename instead; do not run the command from a guessed
   `Downloads` path. `apt` may display a warning about installing a local file; Docker documents that warning as
   ignorable. If package resolution reports a conflict with an existing Docker installation, stop and ask the
   computer owner or course team rather than removing existing Docker data. Continue at action 12; do not run the
   Debian or Fedora branch.

### Debian branch

#### Debian install Git and Docker

6. **Install Git and Docker's repository prerequisites on Debian.** Where: Terminal on Debian 12. Type:

   ```sh
   sudo apt update
   sudo apt install ca-certificates curl git
   git --version
   ```

   Expected: package installation completes and Git prints a version. Recovery: if your user cannot run `sudo`, ask
   the computer administrator to run the documented installation steps; do not switch to Ubuntu package commands.

7. **Add Docker's Debian repository.** Where: the same Terminal. Paste the entire block exactly:

   ```sh
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
     -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
   Types: deb
   URIs: https://download.docker.com/linux/debian
   Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
   Components: stable
   Architectures: $(dpkg --print-architecture)
   Signed-By: /etc/apt/keyrings/docker.asc
   EOF
   sudo apt update
   ```

   Expected: `apt update` includes `download.docker.com/linux/debian` without a signature error. Recovery: confirm
   action 1 says Debian 12 and that `/etc/os-release` contains `VERSION_CODENAME`; do not use these commands on
   a Debian derivative.

8. **Download and install Docker Desktop on Debian.** Where: open the
    [official Debian Desktop page](https://docs.docker.com/desktop/setup/install/linux/debian/) in a browser and use
   its **DEB package** download. In the file manager, open the directory that contains the download and choose
   **Open in Terminal**. Type:

   ```sh
   pwd
   ls -l docker-desktop-amd64.deb
   sudo apt update
   sudo apt install ./docker-desktop-amd64.deb
   ```

   Expected: `pwd` names the actual download directory, `ls` finds the package, and `apt` installs Docker Desktop
   plus its required CLI and Compose dependencies. If the browser localized the directory or renamed the package,
   use its real directory and exact filename. If package resolution reports a conflict, preserve the existing
   installation and its data and ask the computer owner or course team. Continue at action 12; do not run the Fedora
   branch.

### Fedora branch

#### Fedora install Git and Docker

9. **Install Git and the repository helper on Fedora.** Where: Terminal on Fedora 43 or later. Type:

   ```sh
   sudo dnf install git dnf-plugins-core
   git --version
   ```

   Expected: the packages install and Git prints a version. Recovery: if the repository metadata is stale, run
   `sudo dnf makecache --refresh` and retry.

10. **Add Docker's Fedora repository.** Where: the same Terminal. Type:

    ```sh
    sudo dnf config-manager addrepo \
      --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
    ```

    Expected: the repository file is added without an error. Recovery: confirm action 1 says Fedora 43 or later and
    use the current repository command from Docker's Fedora Desktop page if `config-manager` syntax has changed.

11. **Download and install Docker Desktop on Fedora.** Where: open the
    [official Fedora Desktop page](https://docs.docker.com/desktop/setup/install/linux/fedora/) in a browser and use
    its **RPM package** download. In the file manager, open the directory that contains the download and choose
    **Open in Terminal**. Type:

    ```sh
    pwd
    ls -l docker-desktop-x86_64.rpm
    sudo dnf install ./docker-desktop-x86_64.rpm
    ```

    Expected: `pwd` names the actual download directory, `ls` finds the package, and `dnf` installs Docker Desktop
    plus its required CLI and Compose dependencies. If the browser localized the directory or renamed the package,
    use its real directory and exact filename. If package resolution reports a conflict, preserve the existing
    installation and its data and ask the computer owner or course team. Continue at action 12.

## Configure access and start the course package

12. **Complete the desktop integration, QEMU, and KVM access checks.** Where: the desktop application menu and
    Terminal. On GNOME, install and enable the
    [AppIndicator/KStatusNotifierItem extension](https://extensions.gnome.org/extension/615/appindicator-support/)
    so the Docker Desktop tray icon can appear. On a non-GNOME desktop, install the terminal integration if it is
    absent: Ubuntu/Debian use `sudo apt install gnome-terminal`; Fedora uses
    `sudo dnf install gnome-terminal`. Then type:

    ```sh
    qemu-system-x86_64 --version
    ls -l /dev/kvm
    getent group kvm
    id -nG
    ```

    Expected: QEMU is version 5.2 or later, `/dev/kvm` belongs to group `kvm`, and `id -nG` lists `kvm`. If the QEMU
    command is missing, Ubuntu/Debian use `sudo apt install qemu-system-x86`; Fedora uses
    `sudo dnf install qemu-system-x86`; then run the version check again. If `id -nG` does not list `kvm`, type
    `sudo usermod -aG kvm "$USER"`, then sign out of the complete desktop session and sign back in. Opening a new
    terminal is insufficient. This grants access to KVM; do not add yourself to the `docker` group for Docker
    Desktop and do not run course Docker commands with `sudo`.

13. **Launch Docker Desktop and verify its context.** Where: open **Docker Desktop** from the application launcher,
    read and accept the terms on first launch, and wait until the application reports that Docker is running. After
    the first launch, `systemctl --user start docker-desktop` is an optional Terminal start command. In Terminal,
    type:

    ```sh
    command -v docker
    docker context ls
    docker context show
    docker context use desktop-linux
    docker version
    docker compose version
    docker run --rm hello-world
    echo $?
    ```

    Expected: the active context is `desktop-linux`, Docker shows both Client and Server sections, Compose reports
    version 2, `hello-world` prints its confirmation, and status is `0`. Docker Desktop uses a per-user socket, so
    use these commands without `sudo`. If the CLI still targets `default` or `/var/run/docker.sock`, run
    `env | grep -E '^DOCKER_(HOST|CONTEXT)='`; unset `DOCKER_HOST` and `DOCKER_CONTEXT`, remove any stale exports from
    the shell startup file, then run `docker context use desktop-linux` again. Existing host-Engine images and
    volumes remain separate; do not delete them to make Desktop work.

### Linux clone configure and start

14. **Obtain the course package.** Where: Terminal. The release announcement will provide the real URL. Replace the
    placeholder before running:

    ```sh
    cd "$HOME"
    COURSE_REPOSITORY_URL='PASTE_THE_URL_FROM_THE_RELEASE_ANNOUNCEMENT_HERE'
    git clone "$COURSE_REPOSITORY_URL" course-environment
    ```

    Expected: a new `course-environment` directory. Recovery: do not run the placeholder literally. Use
    [Failed clone](troubleshooting.md#failed-clone-or-no-release-url) for network or access errors. If the instructor
    supplied a downloaded `course-environment` folder, place it under your local home directory and skip the clone
    command. Avoid a network share, remote mount, or removable drive for the first run because Docker Desktop must
    share these host files with its Linux virtual machine.

15. **Enter the package and inspect its required files.** Where: Terminal. Type:

    ```sh
    cd "$HOME/course-environment"
    ls compose.yaml .env.example work/verify.sql
    ```

    Expected: all three paths print. Recovery: use `pwd` and `ls`, then enter the directory containing
    `compose.yaml`. Avoid a network share for the first run because host file permissions can differ.

16. **Create the local configuration once.** Where: Terminal in `course-environment`. Type:

    ```sh
    cp .env.example .env
    ```

    Open `.env` with a text editor from the application menu. Keep `POSTGRES_DB=university` and
    `POSTGRES_USER=student`; you may change the two passwords and loopback ports before first startup. Save the file.
    Expected: `ls -la .env` lists it. Recovery: do not overwrite an existing `.env` unless you intend to replace its
    local settings.

17. **Start the environment.** Where: Terminal in `course-environment`. Confirm Docker Desktop is running and
    `docker context show` prints `desktop-linux`, then type:

    ```sh
    docker compose up -d --wait
    docker compose ps
    echo $?
    ```

    Expected: `db` and `pgadmin` show `healthy` and status is `0`. Recovery: run
    `docker compose logs --tail 100` and use [Troubleshooting](troubleshooting.md). If a log says that a supplied host
    file is missing or unreadable, keep the checkout in a local folder under your home directory, allow that folder
    if Docker Desktop displays a file-sharing prompt, confirm ordinary read access with `ls -l`, save the file, and
    retry. Do not apply Engine-specific SELinux relabel commands to make Docker Desktop read the checkout.

18. **Verify the shared files and repair an interrupted seed without deleting volumes.** Where: Terminal in
    `course-environment`. Type:

    ```sh
    ls -l sql/00-seed.sql work/verify.sql pgadmin/servers.json
    docker compose exec db ls -l /course/sql/00-seed.sql /work/verify.sql
    docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -c \
      'SELECT COUNT(*) AS course_count FROM practice.courses;'
    ```

    Expected: the files appear on the host and inside the container, and `course_count` is `8`. Docker Desktop shares
    the local checkout with its virtual machine; edit the files on the host and let the container read them. If the
    container cannot see them, stop only this project with `docker compose down`, move or clone the package into a
    local directory under your home folder, allow the directory if Desktop prompts for sharing, and start it again.

    If `practice.courses` is missing or the count is not `8`, a failed first startup may have initialized PostgreSQL
    before it read `00-seed.sql`. Once file sharing works and `db` is usable, run the existing scoped practice reset,
    then verify all eight rows:

    ```sh
    docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /course/sql/reset-practice.sql
    docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/verify.sql
    ```

    The scoped reset recreates only `practice`; it keeps other database schemas, pgAdmin preferences, Docker Desktop
    volumes, and host `work` files. A full `docker compose down -v` reset is deliberately destructive and is not
    required for this recovery.

### Linux pgAdmin and container queries

19. **Open the pre-registered pgAdmin connection.** Where: a browser. Open `http://localhost:5050`, or use the
    `PGADMIN_PORT` from `.env`. Sign in with `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD`. Open
    **Course → Course PostgreSQL** and enter `POSTGRES_PASSWORD` if prompted. Expected: the supplied server
    expands. Recovery: verify `pgadmin` is healthy and keep the web-app and database passwords distinct.

20. **Run the identity query in pgAdmin.** Where: under **Course PostgreSQL**, expand **Databases**, right-click
    **university**, choose **Query Tool**, paste the SQL below, and press **F5** or the Execute button:

    ```sql
    SELECT current_database() AS database_name, current_user AS user_name;
    ```

    Expected: one row containing `university` and `student`. Recovery: reconnect with `POSTGRES_PASSWORD`.

21. **Use interactive container `psql`.** Where: Terminal in `course-environment`. Type:

    ```sh
    docker compose exec db psql -X -U student -d university
    ```

    Expected: `university=#`. Type the identity query with its semicolon, then type `\q` alone. Recovery: return to
    action 15 if Compose cannot find its file. Do not install a host `psql` package.

22. **Run a one-off query.** Where: Terminal in `course-environment`. Type:

    ```sh
    docker compose exec db psql -X -U student -d university -c \
      'SELECT current_database() AS database_name, current_user AS user_name;'
    echo $?
    ```

    Expected: `university | student` and status `0`. Recovery: put the Docker command on one line if the continuation
    was pasted incorrectly.

### Linux saved SQL files

23. **Create, save, and run your own Linux SQL file through the bind mount.** Where: Terminal in
    `course-environment` and then the desktop's **Text Editor** application.

    1. Make an ignored personal copy; this leaves the tracked `work/verify.sql` unchanged:

       ```sh
       cp work/verify.sql work/my-first-query.sql
       ```

    2. Open **Text Editor** from the desktop application menu. Choose **Open**, select the package's `work` folder,
       and open `my-first-query.sql`. Keep it as plain text, replace all text with the following SQL, then choose
       **Save As**. Confirm the exact filename is `my-first-query.sql`, its folder is `work`, and the encoding is
       **UTF-8** when the editor offers an encoding choice; save the file.

       ```sql
       SELECT 'Saved on my laptop' AS message;
       ```

    3. Return to Terminal and run the saved host file through its container path:

       ```sh
       ls -l work/my-first-query.sql
       docker compose exec -T db psql -X -U student -d university -v ON_ERROR_STOP=1 -f /work/my-first-query.sql
       echo $?
       ```

       Expected: `Saved on my laptop` and status `0`.

    4. Return to the same Text Editor document, change only `Saved` to `Edited`, save, and rerun the preceding Docker
       command. Expected: `Edited on my laptop`. This observable change confirms that the container used your newly
       saved host file.

    5. Run the unchanged supplied verification file:

       ```sh
       ls -l work/verify.sql
       docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/verify.sql
       echo $?
       ```

       Expected: identity `university | student`, count `8`, IDs `101, 102, 103, 104, 105, 201, 202, 301`, and
       status `0`. The host `work` directory is mounted read-only at `/work`. Recovery: save new scripts under host
       `work` and match the filename after `/work/`; inspect ordinary read permissions with `ls -l` and use the
       [missing-file recovery](troubleshooting.md#missing-or-unreadable-bind-mounted-sql) if it is not visible.

### Linux restart

24. **Stop and start while preserving state.** Where: Terminal in `course-environment`. Type:

    ```sh
    docker compose stop
    docker compose start
    docker compose ps
    ```

    Expected: both services return and database, pgAdmin state, and host work files remain. Use
    `docker compose restart` for a direct restart. Recovery: use `docker compose up -d --wait` if the containers do
    not yet exist. Never run a machine-wide Docker cleanup command.

25. **Finish the readiness check.** Where: Terminal and browser. Confirm both services are healthy, pgAdmin and
    container `psql` show the same identity, and the saved file exits `0`. Recovery: record the distribution,
    architecture, command, `echo $?`, and full error before using [Troubleshooting](troubleshooting.md).

<!-- rumdl-enable MD029 -->

Continue with [Query and script workflows](query-and-script-workflows.md). DBeaver is an
[optional local alternative](dbeaver-alternative.md); pgAdmin remains the main course GUI.
