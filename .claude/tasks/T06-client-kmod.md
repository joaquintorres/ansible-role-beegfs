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
- `beegfs_kernel_module` default: make it depend on the toggle —
  `/lib/modules/{{ ansible_kernel }}/extra/beegfs/beegfs.ko` for kmod,
  existing autobuild path otherwise. It's used by the force-format cleanup in
  `create.yml`; for kmod that cleanup should *not* delete the file (the RPM
  owns it) — add `when: not beegfs_client_kmod`.
- Apply any T05 findings (autobuild disable, override.conf).

**Done when:** a client converges with no compiler installed and the
`beegfs` module loads.
