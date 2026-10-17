# Support matrix

Sources: BeeGFS release notes ([7.4.6](https://doc.beegfs.io/7.4.6/release_notes.html),
[7.4.7](https://doc.beegfs.io/7.4.7/release_notes.html),
[8.1](https://doc.beegfs.io/8.1/release_notes.html),
[latest/8.4](https://doc.beegfs.io/latest/release_notes.html)),
[upgrade guide 8.0](https://doc.beegfs.io/8.0.0/advanced_topics/upgrade.html),
[download page](https://www.beegfs.io/c/download/). Checked 2026-10-17.

Legend: ✅ upstream packages + supported · 📦 upstream packages published but
not listed as supported · 🧪 builds via beegfs-kmod, not upstream-supported · ❌ not available · — not targeted by this role

## BeeGFS × EL (upstream)

| BeeGFS | EL7 | EL8 | EL9 | EL10 | Max client kernel | Notes |
|--------|-----|-----|-----|------|-------------------|-------|
| 7.2.x  | ✅ | ✅ | ❌ | ❌ | — | EOL. Not targeted. |
| 7.3.x  | ✅ | ✅ | ✅ | ❌ | — | Not targeted. `connAuthFile` required from 7.3.1; admon removed. |
| 7.4.6  | ❌ | ✅ | ✅ | ❌ | 6.11 | Mandatory stepping stone for 7 → 8 upgrades. |
| 7.4.7  | ❌ | ✅ | ✅ | 📦 | 6.12 | rhel10 repo is published but EL10 isn't in the release notes. |
| 8.0.x  | ❌ | ✅ | ✅ | ❌ | — | New Rust mgmtd, SQLite DB, TLS, `beegfs` CLI, helperd gone. |
| 8.1.x  | ❌ | ✅ | ✅ | ✅ | — | First release with EL10 packages. |
| 8.2.x  | ❌ | ✅ | ✅ | ✅ | — | IPv6 change: 8.0/8.1 `beegfs` CLI & mon not forward-compatible. |
| 8.3.x  | ❌ | ✅ | ✅ | ✅ | — | |
| 8.4.x  | ❌ | ✅ | ✅ | ✅ | 7.0 | Without a license, clients limited to 5. `beegfs-hive-index` → `beegfs-index`. |

Upgrade paths (upstream): `7.x → 7.4.6 → 8.0.1 → 8.1+`. 8.y components
interoperate with any 8.y.z, but features need matching minors.

## What this role will support / test

| BeeGFS | EL8 | EL9 | EL10 | Molecule scenario |
|--------|-----|-----|------|-------------------|
| 7.4.x  | ✅ tested | ✅ supported | 🧪 best-effort, needs `beegfs_version: "7.4.7"` (7.4.6 has no rhel10 repo) | `vagrant-el8` |
| 8.x (8.1+, default 8.4) | ✅ tested | ✅ tested | ✅ tested | `default` (EL9), `vagrant-el10`, `vagrant-all` |
| ≤ 7.3, 8.0 | — | — | — | not tested; may work |

Default `beegfs_version` is **8.4**. Only EL 8/9/10 are supported;
Debian/Ubuntu (and EL7) are removed and rejected by an assert in
`tasks/main.yml`.

## Role behaviour differences by major

| Area | 7.4 | 8.x |
|------|-----|-----|
| Repo URL | `beegfs_7.4.6/dists/beegfs-rhelN.repo` | `beegfs_8.4/dists/beegfs-rhelN.repo` |
| GPG key | `…/gpg/GPG-KEY-beegfs` (verified) | `…/gpg/GPG-KEY-beegfs` (verified) |
| mgmtd setup | `beegfs-setup-mgmtd -p <path>` | `beegfs-mgmtd --init` → `/var/lib/beegfs/mgmtd.sqlite` |
| mgmtd config | `beegfs-mgmtd.conf` | `beegfs-mgmtd.toml` |
| TLS | n/a | cert/key at `/etc/beegfs/{cert,key}.pem` or `tls-disable = true` |
| Auth | `connAuthFile` or `connDisableAuthentication = true` | same for meta/storage/client; mgmtd `auth-file` / `auth-disable` |
| helperd | `beegfs-helperd` required on clients | removed |
| Admin CLI | `beegfs-ctl` (beegfs-utils) | `beegfs` (beegfs-tools) |
| Client module | `kmod-beegfs` (beegfs-kmod) | `kmod-beegfs` (beegfs-kmod) — layout to verify in T05 |
