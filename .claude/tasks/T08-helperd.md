# T08 — `beegfs-helperd` only on 7.x

Removed in 8.0 (client logs to journal).

**Files:** `tasks/client.yml`, `tasks/create.yml`, `tasks/destroy.yml`,
`handlers/main.yml`

Each place that lists `beegfs-helperd` keeps it but adds
`beegfs_major_version is version('8', '<')` to the existing `enable:`/`when:`
condition. For the package list and handler loop use a conditional list
expression rather than splitting tasks.

**Done when:** 8.x converges without trying to install/start helperd, 7.4
unchanged.

## Outcome (2026-11-13)

Done (+4/−6). helperd is guarded by `beegfs_major_version is version('8', '<')`
in the client install list, the create.yml start/enable and destroy.yml
stop/disable items (`enable:`), and the client restart handler's list.
create.yml's "Stop BeeGFS server and client services" is unchanged: it already
skips services that aren't installed.

Verified here: lint, syntax; the four expressions evaluated from the files —
7.4.6: helperd installed, started/stopped, restarted; 8.4: none of these,
`beegfs-client` still handled. On hosts: T13's helperd test (skipped on 8.x).
