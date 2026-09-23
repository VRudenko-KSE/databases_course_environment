# Connect to the course Linux instance

Use this guide when your instructor gives you a Linux account on a shared course server. You do not need a Google Cloud account. Ask the instructor for three things before starting: the server's public IP address or hostname, your own Linux username, and your initial password. Do not put the password in a command, file, or message to another student.

## Open a terminal and connect

On Windows, open **PowerShell** or **Windows Terminal**. On macOS, open **Terminal**. On Linux, open your terminal. Enter the same command on each system, replacing the placeholders:

If you prefer PuTTY on Windows, follow the [PuTTY connection guide](connect-with-putty.md).

```text
ssh YOUR_USERNAME@SERVER_ADDRESS
```

For example, if your username is `student7` and the address is `203.0.113.10`, enter `ssh student7@203.0.113.10`. The example address is a documentation placeholder, not the course server.

On your first connection, SSH may ask whether you trust the server's host key. Check its fingerprint with your instructor before entering `yes`. When asked for a password, type your own initial password and press Enter. The terminal does not display password characters while you type.

The server may require you to change the initial password immediately. Enter the initial password once more, then choose a new, unique password. If you reach a shell without a change prompt, run `passwd` and follow its prompts. Keep the new password private.

## Check your session

These commands run **on the server**, after you have connected:

```bash
whoami
hostname
id -nG
docker compose version
docker ps
```

`whoami` should show your assigned username. The group list should include `docker` if the instructor has granted Docker access. `docker ps` should list running containers or show an empty list; it should not report a permission error. Your account may also have `sudo` access. Use it only for course tasks because Docker and sudo can change the whole shared server.

To leave the server, type `exit`. Commands after that run on your own computer again. Reconnect with the same `ssh YOUR_USERNAME@SERVER_ADDRESS` command.

## Copy a file to or from the server

Run `scp` on **your own computer**, outside the SSH session. Replace the placeholders and paths:

```text
scp my-query.sql YOUR_USERNAME@SERVER_ADDRESS:~/my-query.sql
scp YOUR_USERNAME@SERVER_ADDRESS:~/results.txt ./results.txt
```

The first command uploads a file to your home directory on the server. The second downloads a file to your current local directory. Each command asks for your server password.

## If connection fails

- `ssh` is not recognized: install or enable the OpenSSH client on your computer. See [Microsoft's OpenSSH instructions](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse) for Windows.
- `Connection timed out` or `No route to host`: check the address and your internet connection. Ask the instructor whether the server is running and whether SSH port 22 is reachable.
- `Permission denied`: check your username and password. If this is your first login, ask the instructor to confirm that your account was created and password login is enabled.
- `REMOTE HOST IDENTIFICATION HAS CHANGED`: stop and ask the instructor to verify the server fingerprint. Do not bypass the warning without checking.
- Docker reports permission denied: log out and reconnect so new group membership takes effect; if it persists, ask the instructor to check your `docker` group membership.

The instructor may have already installed Docker on the course server. For a separate Ubuntu machine that you administer yourself, use the [manual Docker installation guide](install-docker-ubuntu-cli.md).

If the instructor runs the course Compose environment on the server and enables public service binding, open
pgAdmin at `http://SERVER_ADDRESS:5050` (or the port they specify). Sign in with the separate pgAdmin credentials
they provide. The server's Linux SSH password is not automatically the pgAdmin or PostgreSQL password. On the
server, save course SQL under your own `course-environment/work/` and follow the
[shared-file workflow](query-and-script-workflows.md#share-files-with-pgadmin).
