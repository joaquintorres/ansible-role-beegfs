# T05 — Spike: beegfs-kmod against current BeeGFS / EL

Upstream: https://gitlab.com/ccad/beegfs-kmod (`build-srpm.sh`,
`beegfs-kmod.spec.tmpl`). Last changes target 7.2.4 / EL 8.4.

On one VM each of EL8, EL9, EL10:

```sh
dnf install -y rpm-build rpmdevtools kernel-devel-$(uname -r) \
  kernel-rpm-macros redhat-rpm-config elfutils-libelf-devel gcc make perl git
dnf download beegfs-client           # from the configured beegfs repo
git clone https://gitlab.com/ccad/beegfs-kmod && cd beegfs-kmod
./build-srpm.sh ../beegfs-client-*.rpm
rpmbuild --rebuild --define "kversion $(uname -r | sed 's/\.[^.]*$//')" \
  ~/rpmbuild/SRPMS/kmod-beegfs-*.src.rpm
```

Check, for BeeGFS 7.4.6 and 8.4:

1. Does the spec find the module sources in the 7.4/8.x `beegfs-client` RPM
   layout (`/opt/beegfs/src/client/client_module_*`)? Note the paths.
2. Does it build without RDMA, and with `BEEGFS_OPENTK_IBVERBS`/in-kernel
   RDMA (8.x may need `BEEGFS_NO_RDMA` / `OFED_INCLUDE_PATH` instead)?
3. Since `kmod-beegfs` *Conflicts* with `beegfs-client`, does it ship
   everything the client service needs: systemd unit `beegfs-client.service`,
   `/opt/beegfs/sbin/beegfs-client` (or init script), `beegfs-client.conf`,
   `beegfs-mounts.conf`, `mount.beegfs`/helper scripts? List what's missing.
4. Does `beegfs-client.service` try to autobuild/rebuild on start? If so, how
   to disable (`/etc/beegfs/beegfs-client-autobuild.conf`
   `buildEnabled=false`?).
5. Is the `files/beegfs-client.service.d/override.conf` `Type=forking` still
   correct for the 7.4/8.x unit?
6. Does `weak-modules` exist on EL10? (EL10 kernel tooling changed; if not,
   the `%post` needs a fallback to plain `depmod`.)
7. Epoch/version on the result: does `Provides: beegfs-client` satisfy
   `beegfs-utils`/`beegfs-tools` dependencies?

**Output:** append findings to this file; if the spec needs changes, put
patches under `files/beegfs-kmod/` (or a fork URL) and reference them from T12.

## How it runs

GitHub Actions, `.github/workflows/kmod-spike.yml` → `.github/kmod-spike/spike.sh`,
in `almalinux:{8,9,10}` containers × BeeGFS {7.4.6, 8.4} (EL10 uses 7.4.7).
Builds against the newest `kernel-devel` in the repos (no booted kernel
needed), then inspects the client RPM, the kmod RPM and a `dnf install`.
Findings are emitted as annotations (readable unauthenticated via
`/repos/joaquintorres/ansible-role-beegfs/check-runs/<id>/annotations`) and
the job summary; RPMs + logs are uploaded as artifacts.
Not covered by CI: question 4/5 at runtime (service start, `Type=forking`)
→ verified in Molecule (T11/T12).

## Findings — run 1 (39079553377, commit ee7d561, beegfs-kmod 614232a)

Build kernels: EL8 `4.18.0-553.174.1.el8_10`, EL9 `5.14.0-687.57.1.el9_8`,
EL10 `6.12.0-211.65.1.el10_2`.

| | 7.4.6 / 7.4.7 (EL10) | 8.4 |
|---|---|---|
| Module sources | `/opt/beegfs/src/client/client_module_7` | `/opt/beegfs/src/client/client_module_8` |
| rpmbuild | ✅ compiles on EL8, EL9, EL10 (job then died on a SIGPIPE in spike.sh, fixed) | ❌ spec hard-codes `client_module_7` |
| Service | `Type=oneshot`, `ExecStart=/etc/init.d/beegfs-client start`, After `beegfs-helperd` | `Type=oneshot`, `ExecStart=/opt/beegfs/sbin/beegfs-client start` |
| Autobuild conf | `buildArgs=-j8`, `buildEnabled=true` | same |
| beegfs-client Requires | `gcc`, `make` (→ installing it drags in a toolchain) | |

Answers so far:
1. Paths noted above; spec needs `client_module_*` → patched.
3. **kmod-beegfs ships only `beegfs.ko`, depmod.d conf and
   `beegfs-client.conf`**, while conflicting with `beegfs-client`: no
   service unit, no start script, no `beegfs-mounts.conf`. → patched to ship
   all beegfs-client files except `/opt/beegfs/src`, keep modes, and set
   `buildEnabled=false`.
4. Both majors' start scripts honour `beegfs-client-autobuild.conf`; the
   patch sets `buildEnabled=false` (runtime behaviour → verify in T11).
5. **`files/beegfs-client.service.d/override.conf` sets `Type=forking`, but
   upstream is `Type=oneshot` + `RemainAfterExit=yes` on 7.4 and 8.4.**
   Overriding to forking is likely wrong now → drop `Type=` from the
   override in T06 (keep `Restart=`; note `Restart=on-failure` with oneshot
   needs systemd ≥ 244 — fine on EL8+).
2, 6, 7: pending run 2.

Patch: `files/beegfs-kmod/0001-client-layout-and-runtime.patch`, applied by
spike.sh (and later by T12's build playbook).
