# Release Checklist

## Container image evidence

Manifest inspection date: **2026-09-12**.

The release candidates were inspected directly with `docker buildx imagetools inspect`. Both tags were available,
so no replacement version was needed. Compose pins the multi-platform image-index digest so Docker selects the
matching native architecture without a forced platform.

<!-- rumdl-disable MD013 -->

| Image | Pinned release reference | Linux amd64 manifest | Linux arm64 manifest | Result |
|---|---|---|---|---|
| PostgreSQL | `postgres:18.6@sha256:4ef4dbc939d61acea57712655ddb4b4ab27419c913f94cca0cd57cb3ea3c2280` | `sha256:7341002d2b8c7c5bdd7542a671a95b36196c0b5b888daf454ae4fc33ba5346d7` | `sha256:6fd9e18b6fedda0a34e4d53ad6fdbd4289a217300af573c31ec7084e6d9cf329` (`arm64/v8`) | Both required architectures present |
| pgAdmin | `dpage/pgadmin4:9.17@sha256:2f4ce946ddf8360680d7eff4eaba1d91859eb6b4003e6623bad5c63a322c2f4d` | `sha256:8cfafd474324cb038b92277ff4f8b01d9576440702fce03eb5ba845fa1405960` | `sha256:a5807e29e73fa0df641a8545b6bdf0cea83b543a924616ef37d34dbe87ea0bed` | Both required architectures present |

<!-- rumdl-enable MD013 -->

Manifest presence is registry evidence, not a native runtime test. The runtime rehearsal below records the actual
host and engine architectures used; native arm64 startup remains a separate release acceptance check until observed.

## Runtime rehearsal evidence

Observed at **2026-09-12T10:36:57Z** on macOS/Darwin 25.6.0 x86_64, with Docker Desktop 4.55.0,
Docker client 29.1.3 (`darwin/amd64`), Docker engine 29.1.3 (`linux/amd64`), and Docker Compose
v2.40.3-desktop.1. The pulled PostgreSQL image ID was
`sha256:a6638641707cdf047e5d5c2781f437e2e809323cab22c70b280be8389fbb7878`; the pulled pgAdmin image ID was
`sha256:78bcd13ffb0a9a6dff344f4c4a212e3b7622cf1a5a83566c79e550b2ab561487`.

The isolated Compose project `kse-practices-01-02-task1-check` used unused host ports 55432 and 55050 and its own
named volumes. Observed results:

- `docker compose up -d --wait` completed with both health checks passing.
- Container psql returned `university|student`, search path `practice, public`, and the exact eight canonical rows.
- pgAdmin returned HTTP 200 with `PING`; its configuration database contained the expected **Course PostgreSQL**
  registration, including `db:5432`, database `university`, user `student`, and SSL mode `prefer`.
- A PostgreSQL-driver connection from inside the pgAdmin container authenticated to `db:5432` as `student` and
  returned database `university`. Task 6 adds the browser interaction evidence below.
- A changed practice row and the pgAdmin registration survived `docker compose stop` followed by startup.
- The stop-on-error reset returned exit 0, restored all eight canonical rows and the original `Databases` title,
  preserved a guard table in `public`, and left both host SQL files byte-for-byte unchanged.
- Project teardown returned exit 0. No containers or volumes with the verification project label remained.

pgAdmin 9.17 validates login addresses and rejects the required classroom-only `.local` domain by default. Compose
therefore sets its supported `PGADMIN_CONFIG_ALLOW_SPECIAL_EMAIL_DOMAINS` option to `['local']`; an isolated startup
first reproduced the rejection, then verified the override with a running container and successful ping.

Cross-platform, native arm64 runtime, installer, novice, disconnected-network, and published-clone checks remain
release gates and must not be marked complete without observed evidence.

## Task 6 local release-candidate verification

Observed at **2026-09-12T17:02:26Z** on macOS 26.6.2 (Darwin 25.6.0) on an Intel x86_64 host, using
Docker Desktop 4.55.0, Docker client/engine 29.1.3, Compose v2.40.3-desktop.1, Git 2.50.1, uv 0.12.9,
CPython 3.14.7, Playwright 1.62.0, and Google Chrome. The separate checker project is
`/private/tmp/course-release-check`; it is not part of this learner package.

The local candidate is identified by the **`local-rc-2026-09-12`** Git tag. Its exact commit is recorded in the
private Task 6 verification report. This local tag is not a published release and does not satisfy the remote
publication gate.

### Acceptance record

<!-- rumdl-disable MD013 -->

| # | Acceptance check | Status | Observed result and remaining gate |
|---:|---|---|---|
| 1 | Clean clone/startup on Windows, macOS, named Linux | Partial | The source package passed isolated startup on this macOS/amd64 host. A clean local clone is recorded separately below after repository assembly. Windows, Ubuntu, Debian, and Fedora installer/runtime checks remain pending. |
| 2 | amd64 and arm64 availability/runtime | Partial | Registry manifests contain Linux amd64 and arm64 variants for both pinned image indexes. Native Linux/amd64 ran here; native arm64 runtime remains pending. |
| 3 | pgAdmin login, registration, connection, restart persistence | Observed on this host | Chrome signed in as `student@course.local`, showed `Course PostgreSQL`, prompted for the database password, connected to `university`, and reconnected after Compose stop/start without registration. Both pgAdmin health probes became healthy. |
| 4 | Equal pgAdmin/psql results and saved mount | Observed on this host | Browser Query Tool and container psql both returned `university | student`; both observed eight rows and IDs `101,102,103,104,105,201,202,301`. `/work/verify.sql` exited 0 through the read-only mount. |
| 5 | Spaces, editor save, PowerShell path | Partial | The tracked UTF-8 scripts ran from the macOS source path containing `KSE/Databases`. The clean local clone uses a path with spaces. A documented Windows editor/PowerShell execution remains pending. |
| 6 | Intentional failure | Observed on this host | A temporary two-statement script failed on the missing table with psql exit 3; the sentinel was absent. |
| 7 | Practice reset and stop/start | Observed on this host | A course-title edit survived stop/start. Reset restored eight exact seed rows and course 101 title `Databases`, kept a `public` guard row, and left the four shipped SQL/work files byte-for-byte unchanged. |
| 8 | Setup blocker diagnosis/recovery | Partial | A second project reproduced `Bind for 127.0.0.1:55433 failed: port is already allocated`; changing its two host ports recovered both services to healthy. Remaining Docker-stopped, missing-PATH, wrong-password, missing-file, and SELinux/bind-mount fault exercises are documented but not all executed on this host. |
| 9 | Offline/pre-pull path | Partial | `docker compose pull` completed, then a new project reached both health checks with `docker compose up -d --pull never --wait`. No host/daemon network was disabled, so a real disconnected-network run and native arm64 pre-pull remain pending. |
| 10 | Timed novice walkthrough | Pending | No novice participant was available. No checkpoint time, helper load, individual completion, or Practice 2 fit is claimed. Use the record in the private TA guide before release. |
| 11 | Published URL/revision and public clone | Pending | No destination remote or access policy was supplied and publication was not authorized. The learner guides therefore retain `COURSE_REPOSITORY_URL`; a student-accessible published clone remains required. |

<!-- rumdl-enable MD013 -->

The [login](images/pgadmin-login.png), [preloaded server](images/pgadmin-preloaded-server.png), and
[Query Tool result](images/pgadmin-query-result.png) are real captures from this pgAdmin 9.17 rehearsal.

### Tested pre-pull path

Run this while connected to the internet and from the package root:

```sh
docker compose pull
```

Confirm the locally selected image architecture and ID:

```sh
docker image inspect postgres:18.6@sha256:4ef4dbc939d61acea57712655ddb4b4ab27419c913f94cca0cd57cb3ea3c2280 \
  --format '{{.Id}} {{.Os}}/{{.Architecture}} {{.Size}}'
docker image inspect dpage/pgadmin4:9.17@sha256:2f4ce946ddf8360680d7eff4eaba1d91859eb6b4003e6623bad5c63a322c2f4d \
  --format '{{.Id}} {{.Os}}/{{.Architecture}} {{.Size}}'
```

This host reported PostgreSQL image ID `sha256:a6638641707cdf047e5d5c2781f437e2e809323cab22c70b280be8389fbb7878`,
`linux/amd64`, 456,470,914 bytes, and pgAdmin image ID
`sha256:78bcd13ffb0a9a6dff344f4c4a212e3b7622cf1a5a83566c79e550b2ab561487`,
`linux/amd64`, 528,550,678 bytes. After the pull, this check forbids another pull:

```sh
docker compose up -d --pull never --wait
```

It passed in a new isolated project on this host. The selected pre-pull route creates no archive, so there is no
archive filename, checksum, or `docker image load` command to publish. If the instructor later chooses archive
distribution, produce and test separate amd64 and arm64 archives; do not infer architecture from a filename or
claim that loading a tag recreates digest resolution without a real load/start test.

### Package and publication gates

The standalone repository includes only learner files, three observed pgAdmin screenshots, the tracked
`work/verify.sql`, and the prompt-only `work/practice-02.sql`. Its ignore rules exclude local `.env` and
untracked learner work. The private TA guide and parent course documents are outside the repository.

Before publication, the instructor must provide the destination URL and access policy, authorize publication,
replace `COURSE_REPOSITORY_URL` in the release announcement, and test the real URL and released revision as a
student. Windows, native arm64, named Linux distribution/SELinux, actual disconnected-network, novice, and
published-clone evidence remain release gates.
