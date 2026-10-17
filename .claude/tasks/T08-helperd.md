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
