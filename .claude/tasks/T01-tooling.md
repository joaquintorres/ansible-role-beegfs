# T01 — Tooling baseline

**Files:** new `requirements.yml`, `molecule/requirements.txt`, `.yamllint`,
new `.ansible-lint`

- `requirements.yml` (collections): `ansible.posix` (mount, sysctl),
  `community.general` (filesystem, modprobe). Keep short module names in
  tasks; they resolve through the `ansible` package routing.
- `molecule/requirements.txt`: `ansible-core>=2.15`, `molecule>=6`,
  `molecule-plugins[vagrant]`, `pytest-testinfra`, `ansible-lint`, `yamllint`.
- `.yamllint`: add `octal-values` and `comments: min-spaces-from-content: 1`
  only if current ansible-lint complains; otherwise leave.
- `.ansible-lint`: `profile: min` plus `skip_list` for `fqcn` and
  `name[casing]` — we are deliberately not doing a style sweep.

**Done when:** `ansible-lint` and `yamllint .` pass on the untouched role
except for the issues fixed in T02–T04.

## Outcome (2026-10-17)

Done. Verified locally with ansible-core 2.19.14, ansible-lint 26.10.1,
yamllint 1.38.0, molecule 26.10.0.

- Added `requirements.yml`, `.ansible-lint`; rewrote
  `molecule/requirements.txt`.
- `.yamllint`: added the settings ansible-lint requires (`comments`,
  `comments-indentation`, `octal-values`) and `indent-sequences: whatever`
  (the role mixes both list styles; not reformatting it).
- `tasks/client.yml`: `mode: 0644` → `mode: "0644"` (implicit octal).
- `meta/main.yml`: added `namespace: stackhpc`, pulled forward from T14,
  so ansible-lint can resolve `stackhpc.beegfs` in `tests/test.yml`.
- Remaining: `ansible-lint` fails only on `include:` (T02). The old
  Molecule playbooks fail to resolve role `ansible-role-beegfs` (T11).
