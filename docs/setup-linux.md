# Linux setup from zero

This guide has separate branches for supported Ubuntu, Debian, and Fedora releases. PostgreSQL, pgAdmin, and `psql`
run in Docker; do not install PostgreSQL server or client packages. Commands run in the desktop's **Terminal**.

## Supported systems and evidence

The vendor pages were checked on **2026-09-12**:

- [Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/) lists 64-bit Ubuntu 26.04 LTS,
  24.04 LTS, and 22.04 LTS. It supports amd64 and arm64, among other architectures.
- [Docker Engine on Debian](https://docs.docker.com/engine/install/debian/) lists Debian 13 and 12. It supports
  amd64 and arm64, among other architectures.
- [Docker Engine on Fedora](https://docs.docker.com/engine/install/fedora/) lists maintained Fedora 44 and 43.
- [Git's Linux page](https://git-scm.com/install/linux) uses each distribution's package manager; the current Git
  source release was 2.55.0 when checked.

The course images publish Linux amd64 and arm64 manifests, and Compose does not force an architecture. The runtime
has been exercised only with a Linux amd64 engine hosted by Docker Desktop on macOS. Native Linux, arm64, Fedora
SELinux, fresh installer, and novice walkthrough evidence are **pending release checks**. The Fedora recovery below
is narrowly scoped from Docker's documented SELinux bind-mount model; it is not claimed as an observed Fedora test.
No installer screenshot is linked because no real Linux installation capture is available.

## Choose and install the distribution branch

Phase links: [OS and architecture preflight](#linux-preflight);
install Git and Docker on [Ubuntu](#ubuntu-install-git-and-docker),
[Debian](#debian-install-git-and-docker), or [Fedora](#fedora-install-git-and-docker);
then [clone, configure, and start](#linux-clone-configure-and-start),
[use pgAdmin and container queries](#linux-pgadmin-and-container-queries),
[run saved SQL files](#linux-saved-sql-files), and [restart](#linux-restart).

<!-- rumdl-disable MD029 -->

### Linux preflight

1. **Identify the distribution and architecture.** Where: open Terminal and type:

   ```sh
   cat /etc/os-release
   uname -m
   ```

   Expected: the first command names a release in the supported list above. `x86_64` means amd64; `aarch64` means
   arm64. Recovery: do not paste commands from another branch. Update to a supported release or use a supported
   course computer if your release is absent. Derivatives such as Linux Mint and Kali are not covered by this guide.

2. **Check for an existing Docker installation before changing packages.** Where: Terminal. On Ubuntu or Debian,

   type:

   ```sh
   dpkg --get-selections | grep -E '^(docker|containerd|runc|podman-docker)'
   ```

   On Fedora, type:

   ```sh
   rpm -qa | grep -E '^(docker|containerd|runc|podman-docker)'
   ```

   Expected on a fresh machine: no output. Recovery: if packages are listed, stop and ask the course team or the
   computer owner which installation owns them. Docker's official instructions identify conflicting packages, but
   removing an existing runtime can affect other projects. This guide never deletes `/var/lib/docker` or existing
   images, containers, or volumes.

### Ubuntu branch

#### Ubuntu install Git and Docker

3. **Install Git and repository prerequisites on Ubuntu.** Where: Terminal on a supported Ubuntu release. Type:

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

5. **Install Docker Engine and Compose on Ubuntu.** Where: Terminal. Type:

   ```sh
   sudo apt install docker-ce docker-ce-cli containerd.io \
     docker-buildx-plugin docker-compose-plugin
   sudo systemctl status docker --no-pager
   ```

   Expected: the packages install and the service says `active (running)`. Recovery: if it is inactive, run
   `sudo systemctl start docker`, then repeat the status command. Continue at action 12.

### Debian branch

#### Debian install Git and Docker

6. **Install Git and repository prerequisites on Debian.** Where: Terminal on Debian 13 or 12. Type:

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
   action 1 says Debian 12 or 13 and that `/etc/os-release` contains `VERSION_CODENAME`; do not use these commands on
   a Debian derivative.

8. **Install Docker Engine and Compose on Debian.** Where: Terminal. Type:

   ```sh
   sudo apt install docker-ce docker-ce-cli containerd.io \
     docker-buildx-plugin docker-compose-plugin
   sudo systemctl status docker --no-pager
   ```

   Expected: the service says `active (running)`. Recovery: if inactive, run `sudo systemctl start docker` and
   repeat the status command. Continue at action 12.

### Fedora branch

#### Fedora install Git and Docker

9. **Install Git and the repository helper on Fedora.** Where: Terminal on Fedora 44 or 43. Type:

   ```sh
   sudo dnf install git dnf-plugins-core
   git --version
   ```

   Expected: the packages install and Git prints a version. Recovery: if the repository metadata is stale, run
   `sudo dnf makecache --refresh` and retry.

10. **Add Docker's Fedora repository and install Docker.** Where: the same Terminal. Type:

    ```sh
    sudo dnf config-manager addrepo \
      --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin
    ```

    If prompted for Docker's GPG key, verify the fingerprint shown by the current
    [official Fedora instructions](https://docs.docker.com/engine/install/fedora/) before accepting it. Expected:
    the five Docker packages install. Recovery: confirm action 1 says Fedora 43 or 44 and use the current command
    from Docker's page if `config-manager` syntax has changed.

11. **Start Docker on Fedora.** Where: Terminal. Type:

    ```sh
    sudo systemctl enable --now docker
    sudo systemctl status docker --no-pager
    ```

    Expected: Docker is enabled and `active (running)`. Recovery: if the journal says `failed to find iptables`,
    follow the narrowly named `iptables-nft` recovery on Docker's Fedora page; for other errors, record
    `sudo journalctl -u docker --no-pager -n 100` and ask the course team.

## Configure access and start the course package

12. **Choose Docker daemon access for this personal learning computer.** Where: Terminal on any of the three
    distributions. The remaining course commands intentionally use `docker` without `sudo`. Docker's
    [Linux post-install guide](https://docs.docker.com/engine/install/linux-postinstall/) warns that membership in
    the `docker` group grants root-level host privileges. On a personal course computer where you accept that
    access, type:

    ```sh
    sudo usermod -aG docker "$USER"
    ```

    Completely sign out of the desktop session and sign back in. Expected: `id -nG` includes `docker`. Recovery: a
    new terminal alone does not refresh group membership; sign out fully or restart the computer. On a managed
    computer, ask the administrator to choose group membership, rootless Docker, or supervised `sudo` access before
    continuing.

13. **Verify Docker and Compose without `sudo`.** Where: a new Terminal after signing in. Type:

    ```sh
    command -v docker
    docker version
    docker compose version
    docker run --rm hello-world
    echo $?
    ```

    Expected: the command path and client/engine versions appear, `hello-world` prints its confirmation, and status
    is `0`. Recovery: if access to `/var/run/docker.sock` is denied, repeat action 12; if the daemon is unavailable,
    run `sudo systemctl start docker`.

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
    supplied a downloaded `course-environment` folder, place it under your home directory and skip the clone command.

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

17. **Start the environment once before any Fedora relabeling.** Where: Terminal in `course-environment`. Type:

    ```sh
    docker compose up -d --wait
    docker compose ps
    echo $?
    ```

    Expected: `db` and `pgadmin` show `healthy` and status is `0`. Recovery: run
    `docker compose logs --tail 100`. On Ubuntu or Debian, use [Troubleshooting](troubleshooting.md). On Fedora with
    SELinux enforcing, continue to action 18 only if the logs or audit records show permission denied on a supplied
    bind-mounted path.

18. **Apply the scoped Fedora SELinux remedy only after a matching denial.** Where: Fedora Terminal in
    `course-environment`. First type `getenforce`; this action does not apply when it prints `Disabled`. Inspect recent
    denials with your administrator or TA:

    ```sh
    sudo ausearch -m AVC -ts recent | tail -n 30
    ```

    If the denial names this checkout's `sql`, `work`, or `pgadmin` content, label only those course-owned paths and
    retry:

    ```sh
    sudo chcon -R -t container_file_t ./sql ./work ./pgadmin
    docker compose up -d --wait
    docker compose ps
    ```

    Expected: the containers can read the supplied files while every bind mount remains read-only in Compose.
    Recovery: do not relabel `$HOME`, `/home`, or any system directory. To restore the distribution's default labels
    on only these paths, run `sudo restorecon -RFv ./sql ./work ./pgadmin`. This remedy must remain marked unverified
    until the release check observes it on Fedora with SELinux enforcing.

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

23. **Run a host SQL file through the bind mount.** Where: Terminal in `course-environment`. Type:

    ```sh
    ls -l work/verify.sql
    docker compose exec db psql -X -v ON_ERROR_STOP=1 -U student -d university -f /work/verify.sql
    echo $?
    ```

    Expected: identity `university | student`, count `8`, IDs `101, 102, 103, 104, 105, 201, 202, 301`, and status
    `0`. The host `work` directory is mounted read-only at `/work`. Recovery: save new scripts under host `work` and
    match the filename after `/work/`; inspect ordinary read permissions with `ls -l` and use the scoped Fedora
    action 18 only for a confirmed SELinux denial.

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
