# T16 — Remove Debian/Ubuntu support

**Files:** `defaults/main.yml`, `tasks/create.yml`, `tasks/main.yml`,
`molecule/vagrant-ubuntu-16.04/`, `molecule/vagrant-ubuntu-18.04/`,
`molecule/*/prepare.yml`, `meta/main.yml` (platforms, done with T14)

- `defaults/main.yml`: delete `beegfs_distro_vars.Debian`. Keep the
  `beegfs_distro_vars[ansible_os_family]` indirection (minimal edit; it still
  works with only `RedHat`).
- `tasks/create.yml`: delete the "add apt key for debian family machines" and
  "Refresh apt repos and install https repo support for Debian" tasks; drop
  the now-redundant `when: ansible_os_family == "RedHat"` on the `rpm_key`
  task.
- `tasks/create.yml`: the `/etc/modules` fallback for kernel modules only
  exists for old Debian; EL always has `/etc/modules-load.d`. Delete the
  `stat` + `/etc/modules` task and the `when:` on the modules-load.d task.
- `tasks/main.yml`: add one `assert` at the top:
  `ansible_os_family == 'RedHat'` and
  `ansible_distribution_major_version in ['8', '9', '10']`, with a message
  naming the supported platforms.
- `git rm -r molecule/vagrant-ubuntu-16.04 molecule/vagrant-ubuntu-18.04`.
- `prepare.yml` files: remove the apt-based python bootstrap (replaced in T12).
- `grep -rn -i 'debian\|ubuntu\|apt' .` should only hit the README history,
  if anything.

**Done when:** role converges on EL and fails with a clear message on any
other OS.

## Outcome (2026-10-17)

Done. Removed Debian distro vars, apt/apt_key tasks, `/etc/modules`
fallback (+ its `stat`), Ubuntu Molecule scenarios and the Ubuntu platform
in `vagrant-all`; prepare bootstraps python3 via dnf; `meta/main.yml`
platforms are EL 8/9/10 (pulled forward from T14). New assert in
`tasks/main.yml` verified to fail on Debian 12 with
"This role supports EL 8, 9 and 10 only, not Debian 12.15.".
`.travis.yml` still mentions apt (CI host), handled by T15.
