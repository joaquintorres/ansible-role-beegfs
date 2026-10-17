# T13 — Update testinfra tests

**Files:** `molecule/tests/test_default.py`

- `test_beegfs_helperd_service`: skip when `beegfs_version` (read from
  `host.ansible.get_variables()`) is ≥ 8.
- add `test_beegfs_storage_service` (`beegfs-storage@8003`).
- add `test_kmod_installed`: `host.package('kmod-beegfs').is_installed`,
  and `beegfs` in `/proc/modules`.
- add `test_no_compiler`: `gcc` not installed on the client.
- add `test_mount_writable`: write/read a file under `/mnt/beegfs`.
- 8.x only: `beegfs health check` exit code 0 on the mgmt host (with
  `BEEGFS_MGMTD_ADDR` set).
- keep flake8-clean.

**Done when:** tests pass on all scenarios.
