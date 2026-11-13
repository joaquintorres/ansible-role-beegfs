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

## Outcome (2026-11-13)

Done in three commits, +64 total (approved ~60): T09a mgmtd (+34),
T09b TLS (+29), T09c tools (+1). Checked against the real 8.4.1 RPMs
(mgmtd, tools, meta, storage, client):

- mgmtd TOML defaults already match the role: `auth-file =
  "/etc/beegfs/conn.auth"`, `tls-cert-file`/`tls-key-file` =
  `/etc/beegfs/{cert,key}.pem`; all keys are top-level (before any table).
  The role sets `auth-disable`, `auth-file`, `tls-disable`, `interfaces`.
- `beegfs-mgmtd --init` creates `/var/lib/beegfs/mgmtd.sqlite` and refuses
  to overwrite it (`creates:`); force-format/destroy delete it.
- `beegfs-setup-meta`/`-storage` 8.4 accept every flag the role passes;
  `originalNodeID` is still written by the daemon → no change.
- 8.4 meta/storage/client confs still have `sysMgmtdHost`,
  `connInterfacesFile`, `connAuthFile`, `connDisableAuthentication` (T07 OK).
- The `beegfs` CLI reads `/etc/beegfs/cert.pem` and `/etc/beegfs/conn.auth`
  by default; the mgmtd address comes from `--mgmtd-addr`/`BEEGFS_MGMTD_ADDR`.

Differences from the plan: no `beegfs_tls_cert`/`beegfs_tls_key` — the cert
step has `creates: cert.pem`, so a pre-placed pair is kept (document, T14).
SAN uses `ansible_all_ipv4_addresses` instead of the default route's
address (works without a default route, covers IB IPs). Key is `0600`.

Verified here: lint, syntax; the TOML task run against a copy of the real
8.4 `beegfs-mgmtd.toml` (one line per key, valid TOML, idempotent, nothing
else touched, skipped on 7.4.6); the cert task run locally (key 0600, cert
0644, SAN, kept on re-run, skipped when disabled or 7.x); cert distribution
across two hosts (client copy identical, mgmt host skips itself); package
lists for 7.4.6/8.4. Not verified: mgmtd starting, TLS handshake, `beegfs
health check` → T13 "Deferred from T09".
