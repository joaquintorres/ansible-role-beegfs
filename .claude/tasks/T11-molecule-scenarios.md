# T11 — Molecule scenarios for EL8/9/10

**Files:** `molecule/default/*`, `molecule/vagrant-all/*`, new
`molecule/vagrant-el8/` and `molecule/vagrant-el10/` (same file set as
`default`: `INSTALL.rst`, `molecule.yml`, `converge.yml` (was
`playbook.yml`), `prepare.yml`). The Ubuntu scenarios are deleted in T16.

`molecule.yml` changes (molecule ≥ 6):

- remove top-level `lint:` and nested `lint:` blocks (lint runs from CI, T15)
- replace the VirtualBox `provider_raw_config_args` (`createhd`/`storageattach`)
  with the libvirt one below
- `INSTALL.rst`: libvirt + `vagrant-libvirt` + `molecule-plugins[vagrant]`
- `driver: name: vagrant`, `provider: name: libvirt`
- platforms: `box: almalinux/8|9|10`, `memory: 2048`, `cpus: 2`, extra disk:
  ```yaml
  provider_raw_config_args:
    - "storage :file, :size => '20G'"
  ```
  (R12: `provider_options` renders `libvirt.storage = …`, but `storage` is a
  method; raw args render `libvirt.storage :file, …`. Check the generated
  Vagrantfile in `~/.cache/molecule/…` on the first run.)
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

## Deferred from T06 (2026-11-03)

- **Autobuild → kmod migration** in `vagrant-el8` (7.4.6) as a Molecule
  `side_effect` playbook: converge with `beegfs_client_kmod: false`, then
  re-converge with the kmod RPM. Expect: `beegfs-client` replaced by
  `kmod-beegfs` (no conflict error), `…/updates/fs/beegfs_autobuild/beegfs.ko`
  gone, `modinfo -n beegfs` under `extra/` or `weak-updates/`, client mounted,
  second converge idempotent. Then `verify` (T13).
