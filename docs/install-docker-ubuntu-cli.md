# Install Docker Engine on Ubuntu from the terminal

This guide installs Docker Engine and the Docker Compose plugin on a supported **64-bit Ubuntu** machine using Docker's official `apt` repository. You need an account that can run `sudo` and an internet connection. The course server is normally configured by the instructor with Ansible; do not reinstall Docker there unless the instructor asks you to. For a personal or separately managed Ubuntu machine, follow the steps below. See Docker's [Ubuntu installation](https://docs.docker.com/engine/install/ubuntu/) and [Linux post-installation](https://docs.docker.com/engine/install/linux-postinstall/) pages for current upstream instructions.

## 1. Check the machine

Open a terminal on the Ubuntu machine and run:

```bash
. /etc/os-release
echo "$PRETTY_NAME"
dpkg --print-architecture
```

Confirm that this is a [supported Ubuntu release](https://docs.docker.com/engine/install/ubuntu/) and a supported 64-bit architecture. The commands below use the machine's Ubuntu codename and architecture automatically. If `docker` was installed previously, review Docker's [conflicting package list](https://docs.docker.com/engine/install/ubuntu/#uninstall-old-versions) before installing the official packages. Do not remove an existing installation or its data without checking what it contains.

## 2. Add Docker's repository

Run these commands on Ubuntu:

```bash
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Then create Docker's `apt` source file:

```bash
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

Refresh the package list:

```bash
sudo apt update
```

The update should include `download.docker.com` without a signature error. If it does not, check the repository file and key path before continuing.

## 3. Install and test Docker

```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker.service
sudo systemctl enable --now containerd.service
sudo docker version
sudo docker compose version
sudo docker run --rm hello-world
```

`hello-world` prints a confirmation message when Docker can download and run a container. The systemd commands make Docker and containerd start now and on future boots. If the service does not start, inspect `sudo systemctl status docker` and `sudo journalctl -u docker --no-pager -n 100`.

## 4. Run Docker without `sudo` (optional)

Only do this on a machine where you are allowed full administrator access. Membership in the `docker` group grants root-level control of the host. On the course server, Ansible already grants this access to configured student accounts.

```bash
sudo groupadd -f docker
sudo usermod -aG docker "$USER"
```

Log out of Ubuntu or the SSH session completely, then log back in. Check the new membership and retry without `sudo`:

```bash
id -nG
docker run --rm hello-world
docker compose version
```

If Docker now reports an error reading `~/.docker/config.json` after you used `sudo docker` earlier, fix ownership of your own Docker configuration directory:

```bash
sudo chown -R "$USER":"$USER" "$HOME/.docker"
chmod -R u+rwX "$HOME/.docker"
```

Run those ownership commands only if that error occurs and the directory exists. They do not change Docker's system data directory.

## 5. Keep the installation healthy

Update Docker through the normal Ubuntu package workflow:

```bash
sudo apt update
sudo apt upgrade
```

On a long-running server, container logs can fill the disk. Ask the server administrator to set [Docker log rotation](https://docs.docker.com/engine/logging/configure/) or use a rotating logging driver before hosting busy services. To check disk use, run `docker system df`. Do not run `docker system prune` on a shared server: it can remove other people's unused images and containers.
