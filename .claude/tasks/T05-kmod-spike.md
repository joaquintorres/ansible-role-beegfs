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
