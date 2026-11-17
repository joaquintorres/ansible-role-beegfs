# Plan: bring stackhpc.beegfs to EL 8/9/10 and BeeGFS 7.4 / 8.x

Status: in progress (2026-10-17, review follow-ups 2026-11-03). Task files live in [`tasks/`](tasks/); the version
chart is in [`support-matrix.md`](support-matrix.md).

## Goal

Make the role deploy a working BeeGFS cluster on **EL 8, 9 and 10**
(Rocky/Alma/RHEL) with **BeeGFS 7.4.x and 8.x**, using a modern Ansible
(ansible-core >= 2.15) and Molecule. The client kernel module comes from
prebuilt `kmod-beegfs` RPMs built with
[ccad/beegfs-kmod](https://gitlab.com/ccad/beegfs-kmod), not from
on-node autobuild.

## Ground rules

- **Minimal edits.** Change only what is needed for EL 8/9/10 + current BeeGFS
  to work. No refactors, no renames of existing variables, no collection
  conversion, no FQCN sweep unless a task breaks without it.
- **Keep the structure.** Same `tasks/*.yml` split (`main` → `create`/`destroy`
  → `mgmt`/`meta`/`oss`/`client`/`rdma`/`tuning`), same `beegfs_enable`
  interface, same `beegfs_oss` / `beegfs_client` list formats, same
  `molecule/<scenario>/` layout with shared `molecule/tests/`.
- **Version branches stay small.** Where 7.4 and 8.x differ, use a
  `when: beegfs_major_version is version('8', '>=')` guard on the existing
  task, or add one sibling task. No separate task trees per version.
- **At most 20 lines of code per task without asking.** Count added +
  changed lines outside `.claude/` (`git diff --numstat -- . ':!.claude'`,
  first column; deleted lines don't count). Before going over 20, stop and ask
  the user explicitly, giving the expected line count and why the smaller
  version isn't enough. Approval covers that task only.
- **Debian/Ubuntu support is removed.** Delete the Debian code paths
  (`apt`/`apt_key` tasks, `beegfs_distro_vars.Debian`), the Ubuntu Molecule
  scenarios and the Debian/Ubuntu `meta/main.yml` platforms, and fail fast on
  anything that isn't EL 8/9/10 (T16).

## What breaks today (and why each edit is necessary)

| # | Problem | Where | Fix (task) |
|---|---------|-------|------------|
| 1 | `include:` was removed in ansible-core 2.16 | `tasks/main.yml`, `tasks/create.yml` | `include_tasks:` (T02) |
| 2 | Repo URL points to `latest-stable/…/beegfs-rhel7.repo`; there is no rhel7 repo for current releases, and `latest-stable` would silently jump majors | `defaults/main.yml` | versioned `beegfs_release/…/beegfs-rhel{{ major }}.repo` (T03) |
| 3 | `nobarrier` mount option was removed from XFS (kernel ≥ 4.19); EL9/10 refuse to mount | `beegfs_mount_opts` | drop `nobarrier` (T04) |
| 4 | Client module autobuild needs gcc + kernel-devel on every client, and `/etc/init.d/beegfs-client rebuild` path changed | `tasks/client.yml` | install prebuilt `kmod-beegfs` RPM (T05, T06) |
| 5 | Since 7.3.1 services refuse to start without `connAuthFile` (or explicit `connDisableAuthentication`) | all services | write a shared secret / toggle (T07) |
| 6 | `beegfs-helperd` removed in 8.0 | `client.yml`, `create.yml`, `destroy.yml`, handlers, tests | guard by version (T08) |
| 7 | 8.x mgmtd is a rewrite: no `beegfs-setup-mgmtd`, config is `beegfs-mgmtd.toml`, data is SQLite (`--init`), TLS cert required unless disabled | `tasks/mgmt.yml` | 8.x branch in `mgmt.yml` (T09) |
| 8 | 8.x: `beegfs-ctl` replaced by `beegfs` (package `beegfs-tools`), needs TLS cert/auth on the node | `client.yml` (beegfs-ctl copy task) | install `beegfs-tools`, distribute cert (T09) |
| 9 | RDMA package names differ on EL8+ (`libibmad` folded into `infiniband-diags`/`rdma-core`) | `beegfs_distro_vars.RedHat.rdma_dev_pkgs` | per-EL list (T10) |
| 10 | Modules used by short name now live in `ansible.posix` / `community.general` | `mount`, `sysctl`, `filesystem`, `modprobe` | `requirements.yml` (T01) |
| 11 | Molecule config uses removed keys (`lint:` blocks, `provider_raw_config_args`, CentOS 7.5 boxes, python2 bootstrap); Travis CI is dead | `molecule/`, `.travis.yml` | rewrite scenarios (T11–T13) |
| 12 | `meta/main.yml` advertises EL7/stretch/xenial/bionic, Ansible 2.5 | `meta/main.yml` | update platforms (T14) |
| 13 | Debian/Ubuntu paths use deprecated `apt_key` and Debian 9 repos; now out of scope | `create.yml`, `defaults/main.yml`, Ubuntu scenarios | remove (T16) |

## Kernel module strategy (beegfs-kmod)

`beegfs-kmod` takes a `beegfs-client` RPM, repackages its module sources into
an SRPM (`build-srpm.sh`), and `rpmbuild --rebuild --define "kversion <uname -r
without arch>"` produces `kmod-beegfs-<ver>.rpm`. That package:

- **Provides** `beegfs-client` and **Conflicts** with `beegfs-client` /
  `beegfs-client-dkms` → the role installs `kmod-beegfs` *instead of*
  `beegfs-client`.
- Installs `beegfs.ko` to `/lib/modules/<kversion>.<arch>/extra/beegfs/` and
  registers it with `weak-modules`, so it survives kABI-compatible kernel
  updates within one EL minor stream.
- `Release` is copied from `beegfs-client`, so builds for two kABI streams
  get the same NEVR and cannot share a repo → the patch appends a kernel tag
  to `Release` (T05 patch v3).
- Accepts `kmod_name_extra` / `build_extra_options` for MOFED builds
  (`kmod-beegfs-mofed`).
- Was last touched for BeeGFS 7.2.4 / EL 8.4 → **must be validated against
  7.4 and 8.x client RPM layouts first (T05, the spike).** If the spec needs
  changes, carry patches in this repo (or a fork) — do not block on upstream.

Role side (T06): add `beegfs_client_kmod` (default `true`) and
`beegfs_client_kmod_packages` (default `["kmod-beegfs"]`). Real deployments
publish the RPMs to a **site repo** that the hosts already have configured;
the role only installs by package name and does not upload RPM files.
Molecule is the one exception and passes a local RPM path built in
`prepare.yml`. When `false`, keep the existing
autobuild path untouched for anyone who still wants it. Because the default
is `true` and `kmod-beegfs` conflicts with `beegfs-client`, T06 also migrates
existing autobuild clients (remove `beegfs-client` and the stale autobuild
module before installing).

Build side: a standalone playbook `molecule/shared/build-kmod.yml` (reused by
Molecule `prepare.yml`, also usable against a real build host) that downloads
the matching `beegfs-client` RPM, clones `beegfs-kmod`, builds SRPM + RPM for
the target's running kernel and fetches it back.

## BeeGFS version handling

New defaults (T03):

```yaml
beegfs_version: "8.4"          # default; repo directory: beegfs_<version>
beegfs_major_version: "{{ beegfs_version.split('.')[0] }}"
```

- 7.4 repos are published per patch release (`beegfs_7.4.6`), 8.x per minor
  (`beegfs_8.4`) — `beegfs_version` is used verbatim in the URL, so both work.
- The role does **not** perform major upgrades (7 → 8 needs `--import-from-v7`,
  manual TOML migration, hard-link migration). Document that; fail fast if
  `beegfs_update: true` would cross a major (T03).

## Molecule (T11–T13)

Keep `molecule/default` + `molecule/vagrant-all` + shared `molecule/tests/`.
Delete the two Ubuntu scenarios and add EL ones with the same file layout:

| Scenario | Boxes | BeeGFS |
|----------|-------|--------|
| `default` | `almalinux/9` | 8.4 |
| `vagrant-el8` | `almalinux/8` | 7.4.6 |
| `vagrant-el10` | `almalinux/10` | 8.4 |
| `vagrant-all` | `almalinux/8`, `/9`, `/10` | 8.4 |

Driver: `vagrant` via `molecule-plugins[vagrant]`, provider **libvirt** only
(second disk via `provider_options`/`libvirt__storage`; disk shows up as
`/dev/vdb`). VirtualBox config is removed.

Containers (podman/docker) are not viable: the client needs a real kernel and
the OSS needs a block device to format.

## Decisions (2026-10-17)

1. **Default `beegfs_version`: `8.4`.** 7.4.6 stays supported by setting the
   variable. Existing 7.x users must pin it before upgrading the role (README
   + the major-version guard in T03).
2. **Molecule provider: libvirt.** VirtualBox config is removed.
3. **kmod RPMs come from a site repo.** The role installs `kmod-beegfs` by
   name; no RPM upload logic in the role.
4. **8.x TLS: self-signed certificate** generated on the mgmt host and
   distributed to nodes that run `beegfs-tools`. User-supplied cert/key
   override it; `beegfs_tls_disable` exists but defaults to `false`.
5. **Debian/Ubuntu support removed**, including role code paths (T16).
6. **Work happens on a feature branch** (`el8-9-10`) from 2026-11-03 on, merged
   to `master` once T13 passes. `master` at `36bb3a1` already defaults to 8.4
   but cannot deploy it (helperd, 7.x mgmtd setup) until T08/T09 land.

## Review follow-ups (2026-11-03)

Found reviewing T01–T05/T16; each is folded into the task named.

| # | Issue | Task |
|---|-------|------|
| R1 | `master` defaults to 8.4 but can't deploy it | Decision 6 |
| R2 | Cross-major guard only runs with `beegfs_update: true`, but the repo file is rewritten (`force: true`) on every run → a later `dnf upgrade` silently crosses majors | T03 follow-up |
| R3 | Unquoted `beegfs_version: 8.4` is a float → `.split` fails | T03 follow-up |
| R4 | Spike infers `%post`/`weak-modules` success from `dnf install` exit code, but scriptlet failures don't fail dnf (and `depmod -a` masks it) | T05 run 4 |
| R5 | "`Provides: beegfs-client` satisfies tools" unproven unless tools actually require `beegfs-client` | T05 run 4 |
| R6 | Patch ships configs as plain `%config` → upgrades replace role-templated `beegfs-mounts.conf` | T05 patch v3 |
| R7 | Same NEVR for every kernel build | T05 patch v3 |
| R8 | RDMA build (question 2) never exercised; `BEEGFS_OPENTK_IBVERBS` likely obsolete | T05 run 4, T06, T12 |
| R9 | `spike.sh` needs `GITHUB_WORKSPACE`; workflow has no `permissions:` | T05 |
| R10 | Existing clients: `kmod-beegfs` conflicts with installed `beegfs-client`; stale autobuild `.ko` in `updates/` may shadow kmod | T06 |
| R11 | Proposed kmod `beegfs_kernel_module` path is wrong after a kABI-compatible kernel update | T06 |
| R12 | libvirt extra disk must use `provider_raw_config_args`, not `provider_options` | T11 |

## Order of work

T01 → T05 (spike; may change T06) → T16 → T02–T04 → T06–T10 → T11–T13 →
T14–T15. Each task is small enough for one commit.

Remaining from 2026-11-03: branch → T03 follow-up → T05 run 4 + patch v3 →
T06–T10 → T11–T13 → T14–T15.
