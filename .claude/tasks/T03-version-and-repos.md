# T03 — Pin BeeGFS version, versioned repos

**Files:** `defaults/main.yml`, `tasks/create.yml`

```yaml
beegfs_version: "8.4"
beegfs_major_version: "{{ beegfs_version.split('.') | first }}"
beegfs_distro_vars:
  RedHat:
    beegfs_repo_url: "https://www.beegfs.io/release/beegfs_{{ beegfs_version }}/dists/beegfs-rhel{{ ansible_distribution_major_version }}.repo"
    beegfs_repo_key: "https://www.beegfs.io/release/beegfs_{{ beegfs_version }}/gpg/GPG-KEY-beegfs"
    beegfs_repo_file: "/etc/yum.repos.d/beegfs.repo"
```

- Verify the 7.4 key path (`GPG-KEY-beegfs` vs old `RPM-GPG-KEY-beegfs`) with
  a real download before committing.
- Repo file name change: also remove the old `beegfs-rhel7.repo` if present
  (one `file: state=absent` task) so hosts don't end up with two repos.
- Add an `assert` in `create.yml`: when `beegfs_update` is true and installed
  `beegfs-common`/`beegfs-mgmtd` major differs from `beegfs_major_version`,
  fail with a pointer to the upstream upgrade guide.
- Debian entries are deleted in T16; don't touch them here.

**Done when:** a fresh EL8/9/10 host gets the right repo for both `7.4.6`
and `8.4`.

## Outcome (2026-10-17)

Done. Probed URLs (HTTP 200 unless noted):

| Release | rhel8 | rhel9 | rhel10 | key |
|---------|-------|-------|--------|-----|
| 8.4     | ✅ | ✅ | ✅ | `gpg/GPG-KEY-beegfs` |
| 7.4.6   | ✅ | ✅ | 404 | `gpg/GPG-KEY-beegfs` (`RPM-GPG-KEY-beegfs` is 404) |
| 7.4.7   | — | ✅ | ✅ | — |

- `defaults/main.yml`: `beegfs_version: "8.4"`, `beegfs_major_version`,
  versioned RedHat repo/key URLs, repo file `/etc/yum.repos.d/beegfs.repo`.
- `tasks/create.yml`: removes old `beegfs-rhel7.repo`; `get_url` now
  `force: true` so changing `beegfs_version` rewrites the repo file (only
  reports changed when content differs); when `beegfs_update` is true,
  `package_facts` + `assert` refuse to cross major versions (expression
  tested against sample package sets).
