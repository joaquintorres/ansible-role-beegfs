# T14 — meta/main.yml and README

**meta/main.yml:** `namespace: stackhpc`, `min_ansible_version: "2.15"`,
platforms `EL: ["8", "9", "10"]` only.

**README:** keep structure; update only:
- "last tested" line → ansible-core version used in T11.
- Example playbook: add `beegfs_version`, `beegfs_conn_auth_secret`,
  `beegfs_client_kmod_packages`; device names.
- New short section "Client kernel module" pointing to beegfs-kmod and
  `molecule/shared/build-kmod.yml`.
- Link `.claude/support-matrix.md` content (copy the "What this role will
  support" table into README).
- Notes: default is now 8.4 — **existing 7.x clusters must set
  `beegfs_version` before upgrading the role**; no major-version upgrades;
  8.x license/5-client limit; self-signed TLS cert and how to supply your own;
  `kmod-beegfs` must be in a site repo; EL 8/9/10 only (Debian/Ubuntu removed).
- Example inventory: `ansible_user=centos` → `rocky`/`almalinux`.
- Tests section: new scenario names, libvirt deps
  (`vagrant-libvirt`, `molecule-plugins[vagrant]`).
