# T15 — Replace Travis with GitHub Actions

**Files:** delete `.travis.yml`, add `.github/workflows/lint.yml`,
update README badge.

Lint-only job (GitHub runners can't run nested libvirt reliably):
`pip install -r molecule/requirements.txt`,
`ansible-galaxy collection install -r requirements.yml`, `yamllint .`,
`ansible-lint`, `ansible-playbook tests/test.yml -i tests/inventory
--syntax-check` (keep the `stackhpc.beegfs` symlink trick from Travis).

Molecule stays a manual/local run; document it in README.
