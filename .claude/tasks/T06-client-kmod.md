# T06 — Client installs prebuilt `kmod-beegfs`

**Files:** `defaults/main.yml`, `tasks/client.yml`, `tasks/create.yml`

```yaml
# Install a prebuilt client kernel module (see https://gitlab.com/ccad/beegfs-kmod)
# instead of building it on the node.
beegfs_client_kmod: true
# Package names, local RPM paths or URLs passed to the package manager.
beegfs_client_kmod_packages: ["kmod-beegfs"]
```

- `client.yml`: when `beegfs_client_kmod`, install
  `beegfs_client_kmod_packages` (+ `beegfs-utils`, + `beegfs-helperd` per
  T08, + `beegfs-tools` per T09) instead of `beegfs-client`; skip the
  autobuild `lineinfile`, kernel-devel, gcc and rebuild tasks
  (wrap the existing four in one `block` with
  `when: not beegfs_client_kmod | bool` — don't rewrite them).
- RPMs come from a site repo, so the default is just a package name. Local
  paths still work through `dnf` (Molecule uses this); set
  `disable_gpg_check: true` only when an item ends in `.rpm`. No upload logic.
- `beegfs_kernel_module` stays the autobuild path (R11: with kmod the module
  can be in `extra/` *or* `weak-updates/` depending on the running kernel, so
  no single path is right). It's used by the force-format cleanup in
  `create.yml`; for kmod that cleanup must *not* delete the file (the RPM
  owns it) — add `when: not beegfs_client_kmod`.
- **Migration from autobuild (R10).** Default is `true`, so existing clients
  have `beegfs-client` installed and the conflicting `kmod-beegfs` install
  would fail. Before installing, when `beegfs_client_kmod`: stop the client,
  `package: name=beegfs-client state=absent`, and remove
  `beegfs_kernel_module` (the unowned autobuild `.ko` under `updates/`, which
  depmod would otherwise prefer), then `depmod -a`. Same pair of tasks,
  guarded by `'beegfs-client' in ansible_facts.packages` (facts from T03).
- RDMA: the "Define client kernel build for IB" `lineinfile` only applies to
  autobuild, so it moves into the `not beegfs_client_kmod` block; update its
  `buildArgs` per T05 run 4 (R8) only if 7.4/8.x no longer accept
  `BEEGFS_OPENTK_IBVERBS`.
- Apply T05 findings: autobuild is disabled by the package;
  `files/beegfs-client.service.d/override.conf` drops `Type=forking` (upstream
  is `Type=oneshot` + `RemainAfterExit=yes`), keeps `Restart=`/`RestartSec=`.
- kmod RPMs are kernel-specific (R7): document that the site repo needs a
  build per kABI stream; the client `beegfs` module load check in T13 catches
  a mismatch.

**Done when:** a client converges with no compiler installed and the
`beegfs` module loads, and a client previously deployed with autobuild
converges to `kmod-beegfs` (with `modinfo -n beegfs` pointing at the kmod
module, not `beegfs_autobuild`).
