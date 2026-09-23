# Connect to the course Linux instance with PuTTY (Windows)

Ask your instructor for the server's public IP address or hostname, your Linux username, your initial password, and the server's SSH host-key fingerprint. You do not need a Google Cloud account.

1. Download the Windows installer from the [PuTTY project's download page](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html). Install it and open **PuTTY** from the Start menu.
2. In **Session**, enter the server address in **Host Name (or IP address)**. Set **Port** to `22` unless your instructor gave you another port. Select **SSH**. Optionally enter `Course server` under **Saved Sessions** and select **Save**.
3. Select **Open**. On the first connection, compare the displayed host-key fingerprint with the one from your instructor. Select **Accept** only when they match. If a saved key later changes unexpectedly, stop and ask the instructor to verify it.
4. At `login as:`, type your assigned username. At `Password:`, type your initial password and press Enter. The password is not displayed as you type. If prompted to change it, follow the prompts; otherwise run `passwd` after login and choose a new, private password.
5. Run `whoami`, `hostname`, `id -nG`, `docker compose version`, and `docker ps`. Your username should match; the group list should include `docker`; Docker should not show a permission error. Type `exit` to disconnect.

For later sessions, select your saved session, then **Load** and **Open**. The saved session stores the address and settings, not your password. If login fails, check the username, password, and port; if Docker access fails, log out and reconnect so group membership takes effect. See the [general connection guide](connect-to-instance.md#if-connection-fails) for more errors.

## Copy files with PSCP

The PuTTY installer also includes **PSCP**. Run these commands in **Windows PowerShell on your computer**, not in the PuTTY server window. Replace the placeholders:

```powershell
pscp .\my-query.sql YOUR_USERNAME@SERVER_ADDRESS:~/my-query.sql
pscp YOUR_USERNAME@SERVER_ADDRESS:~/results.txt .\results.txt
```

The first command uploads a file; the second downloads one. If the server uses another SSH port, add `-P PORT` before the source path. Check the host-key fingerprint before accepting a first connection. For files used by the Docker course environment, upload into your own `course-environment/work/` directory on the server, then use `/work/filename.sql` inside the containers. If PowerShell cannot find `pscp`, reopen PowerShell after installation or run `pscp.exe` from PuTTY's installation folder.

The [PuTTY manual](https://the.earth.li/~sgtatham/putty/0.84/htmldoc/) covers host-key verification, sessions, and PSCP.
