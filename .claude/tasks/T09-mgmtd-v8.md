# T09 — 8.x management service, TLS, `beegfs-tools`

**Files:** `defaults/main.yml`, `tasks/mgmt.yml`, `tasks/client.yml`,
new `templates/beegfs-mgmtd.toml.j2`? (prefer `lineinfile` on the shipped
TOML — less to maintain)

In `mgmt.yml`, guard the existing `beegfs-setup-mgmtd` and
`beegfs-mgmtd.conf` tasks with `beegfs_major_version is version('8', '<')`
and add the 8.x siblings:

1. `command: /opt/beegfs/sbin/beegfs-mgmtd --init` with
   `creates: /var/lib/beegfs/mgmtd.sqlite`. (`beegfs_mgmt_path` is unused
   on 8.x — document it; optionally pass `--db-file` if it's set to a
   non-default value. Keep it minimal: don't.)
2. TOML settings via `lineinfile` (regexp `^#?\s*key\s*=`):
   `interfaces = [..]` from `beegfs_interfaces`, `auth-file` / `auth-disable`
   (T07), `tls-cert-file`/`tls-key-file` or `tls-disable`.
3. TLS (decided: self-signed by default). New vars `beegfs_tls_disable: false`,
   `beegfs_tls_cert`/`beegfs_tls_key` (content, optional). If not provided,
   generate a self-signed pair on the mgmt host with
   `community.crypto` *or* a single `openssl req` command with `creates:`
   (prefer openssl — no extra collection), then `slurp` + copy
   `cert.pem` to every node that runs `beegfs-tools`.
4. `client.yml`: on 8.x install `beegfs-tools`; the "Copy default
   beegfs-client config file to enable beegfs_ctl" task stays (harmless).
5. Licensing: no task. README note that 8.4 without a license limits to
   5 clients; `/etc/beegfs/license.pem` is user-provided.

Verify on 8.4: do `beegfs-setup-meta`/`beegfs-setup-storage` still accept
`-p -m -f -r -S` and still create `originalNodeID`? (used as `creates:`). If
not, adjust only the flags/`creates:` that changed.

**Done when:** 8.4 mgmt/meta/storage/client converge idempotently on EL9 and
`beegfs health check` passes on the mgmt node.
