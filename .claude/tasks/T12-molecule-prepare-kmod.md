# T12 — Molecule prepare builds the kmod RPM

**Files:** new `molecule/shared/build-kmod.yml`; each scenario's
`prepare.yml` imports it.

`prepare.yml` drops the python2 `raw` bootstrap (EL8+ ship python3 /
platform-python) and the apt bits.

`build-kmod.yml` (tasks file, usable standalone against a build host):

1. Add the BeeGFS repo (`include_role` with `tasks_from` is overkill — just
   `get_url` the same URL as `defaults/main.yml`).
2. Install build deps (list from T05) incl. `kernel-devel-{{ ansible_kernel }}`.
3. `dnf download beegfs-client` into a build dir.
4. `git clone https://gitlab.com/ccad/beegfs-kmod` at a pinned commit
   (`beegfs_kmod_git_version`, the commit T05 run 4 used), apply
   `files/beegfs-kmod/*.patch` (v3).
5. `build-srpm.sh`, then `rpmbuild --rebuild --define "kversion …"`
   (`ansible_kernel` minus `.{{ ansible_architecture }}`), `creates:` on the
   result.
   Also `--define "beegfs_release <client release>.k<kversion, - → _>"`
   (R7, as in `spike.sh`). Pass `build_extra_options` (default `""`) only
   for MOFED; in-kernel RDMA is built by default (T05 run 4).
6. `set_fact` the resulting RPM path; converge passes it as
   `beegfs_client_kmod_packages`.
7. Remove build deps afterwards (`gcc`, `kernel-devel`) so the test proves the
   client needs no toolchain.

**Done when:** prepare on a fresh box yields `kmod-beegfs-*.x86_64.rpm` for
both 7.4.6 and 8.4.

## Phase 1 (2026-11-13) — committed, waiting for the first CI run

Approved plan: phase 1 = `default` (EL9, 8.4) green; phase 2 = el8/el10 +
multi-node `vagrant-all`; phase 3 = side-effect variants. Runs on GitHub
Actions with KVM (`.github/workflows/molecule.yml`), failures surface as
annotations. Shared `molecule/shared/{prepare,converge,build-kmod}.yml`
and `molecule/INSTALL.rst` replace the per-scenario copies; the role is
referenced as `stackhpc.beegfs` (meta namespace + role_name). Prepare
updates the kernel and reboots so `kernel-devel-$(uname -r)` exists; the
kmod RPM is left at `/var/tmp/kmod-beegfs.rpm` for converge.
