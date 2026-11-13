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

## Outcome (2026-11-13)

Done (1 line): `libibmad` → `infiniband-diags`, which provides `libibmad`
on EL8+. Checked against AlmaLinux 8/9/10 BaseOS + AppStream repo metadata
and the BeeGFS repos:

- `librdmacm`, `libibumad`, `rdma-core`, `libibverbs`, `libibverbs-utils`:
  BaseOS on EL8/9/10.
- `infiniband-diags`: BaseOS on EL8, AppStream on EL9/10.
- `libbeegfs-ib`: present for 7.4.6 (EL8/9), 7.4.7 (EL10) and 8.4
  (EL8/9/10) — not dropped in 8.x.
- `rdma.yml`'s modules (`ib_umad`, `ib_uverbs`, `rdma_ucm`) are stock EL
  kernel modules; unchanged.

Not verified: an actual install (no dnf here) → T11 "Deferred from T10".
