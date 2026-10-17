# T10 — RDMA packages on EL8+

**Files:** `defaults/main.yml`

Check on EL8/9/10 which of `librdmacm libibmad libibumad rdma-core
libibverbs libibverbs-utils libbeegfs-ib` exist. Expected: `libibmad` is
gone/merged (`infiniband-diags`), `libbeegfs-ib` exists for 7.4 but may be
dropped/renamed in 8.x. Fix the list (use a per-major-version expression only
if 7.4 and 8.x differ). Molecule runs with `beegfs_rdma: false`, so add one
`ansible -m dnf -a "name=… state=present" --check` per EL to the T11
verify notes.

**Done when:** `tasks/rdma.yml` installs cleanly on EL8/9/10.
