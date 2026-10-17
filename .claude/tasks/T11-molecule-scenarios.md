# T11 — Molecule scenarios for EL8/9/10

**Files:** `molecule/default/*`, `molecule/vagrant-all/*`, new
`molecule/vagrant-el8/` and `molecule/vagrant-el10/` (same file set as
`default`: `INSTALL.rst`, `molecule.yml`, `converge.yml` (was
`playbook.yml`), `prepare.yml`). The Ubuntu scenarios are deleted in T16.

`molecule.yml` changes (molecule ≥ 6):

- remove top-level `lint:` and nested `lint:` blocks (lint runs from CI, T15)
- remove the VirtualBox `provider_raw_config_args` (`createhd`/`storageattach`)
- `INSTALL.rst`: libvirt + `vagrant-libvirt` + `molecule-plugins[vagrant]`
- `driver: name: vagrant`, `provider: name: libvirt`
- platforms: `box: almalinux/8|9|10`, `memory: 2048`, `cpus: 2`, extra disk:
  ```yaml
  provider_options:
    storage: ":file, :size => '20G'"
  ```
- `provisioner.playbooks.prepare/converge`; `inventory.group_vars.all`
  carries `beegfs_version` so one converge playbook serves every scenario
- `verifier: name: testinfra`, `directory: ../tests`
- `dependency: name: galaxy`, `options: requirements-file: ../../requirements.yml`

`converge.yml`: same role vars as today, but `dev: /dev/vdb`,
`beegfs_interfaces: ["{{ ansible_default_ipv4.interface }}"]` (EL uses
`eth0`/`ens*` depending on box), `beegfs_conn_auth_secret: molecule-test`,
`beegfs_client_kmod_packages` from prepare (T12). Role name: use
`role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') | basename }}"`.

Scenario → version map in `plan.md`.

**Done when:** `molecule test` and `molecule test -s vagrant-el8|vagrant-el10`
pass, including idempotence.
