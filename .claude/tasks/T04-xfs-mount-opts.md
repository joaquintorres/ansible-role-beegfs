# T04 — Drop `nobarrier`

**Files:** `defaults/main.yml`

Remove `nobarrier` from `beegfs_mount_opts`. It was removed from XFS in
Linux 4.19 and mounts fail on EL9/10. Leave other options as they are
(`largeio,inode64,swalloc,allocsize=…` are still valid).

Also check `beegfs_filesystem_opts` (`-K -d su=128k,sw=8 -l version=2,su=128k
-isize=512`) on EL10 xfsprogs; adjust only if mkfs rejects it.

**Done when:** OSS mount succeeds on EL9 in Molecule.

## Outcome (2026-10-17)

`nobarrier` removed. `beegfs_filesystem_opts` not yet checked against EL10
xfsprogs (no mkfs.xfs in the dev container) → verify in the T11 Molecule run.
