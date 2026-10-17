# T02 — `include:` → `include_tasks:`

**Files:** `tasks/main.yml`, `tasks/create.yml`

Mechanical rename of all 8 `include:` uses. Loop vars (`loop_control`,
`vars`) already work with `include_tasks`. Watch the `failed_when` on the
`oss.yml` include — it's not valid on `include_tasks`; move the check into
`oss.yml` as an `assert` at the top (same condition).

**Done when:** `ansible-playbook tests/test.yml --syntax-check` passes on
ansible-core 2.16+.

## Outcome (2026-10-17)

Done. 9 `include:` → `include_tasks:`. The `failed_when` on the `oss.yml`
include became an `assert` at the top of `tasks/oss.yml`. Syntax check and
ansible-lint pass on ansible-core 2.19.14.
