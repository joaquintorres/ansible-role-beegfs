# T07 — Connection authentication

Since 7.3.1 every service refuses to start unless `connAuthFile` is set or
`connDisableAuthentication = true`.

**Files:** `defaults/main.yml`, `tasks/create.yml` (one block near
"Create connInterfacesFile"), `mgmt.yml`, `meta.yml`, `oss.yml`, `client.yml`

```yaml
# Shared secret for BeeGFS connection authentication. Set to "" to disable
# authentication (connDisableAuthentication = true). Use vault.
beegfs_conn_auth_secret: ""
beegfs_conn_auth_file: /etc/beegfs/conn.auth
```

- `create.yml`: `copy: content="{{ beegfs_conn_auth_secret }}" mode=0400
  no_log=true` when the secret is set.
- Each existing "Specify connInterfacesFile" `lineinfile` gets one sibling
  `lineinfile` setting `connAuthFile` or `connDisableAuthentication`
  (meta, storage per-port conf, client per-mgmt conf, mgmtd 7.4 conf).
  8.x mgmtd TOML is handled in T09.
- Molecule: set a fixed test secret (exercise the real path).

**Done when:** all services start with auth enabled and with auth disabled.
