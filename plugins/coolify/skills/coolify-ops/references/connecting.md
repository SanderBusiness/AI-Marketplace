# Connecting to a Coolify server

Servers are reached by SSH host alias, defined in `~/.ssh/config` on the operator's
machine — never by hardcoding an IP address, username, or key path in a prompt, a repo
file, or persistent memory. A typical entry:

```
Host <alias>
    HostName <ip-or-hostname>
    User root
    IdentityFile ~/.ssh/<alias>_ed25519
    IdentitiesOnly yes
```

Once an alias exists, connect and run commands with:

```
ssh <alias> '<command>'
```

Which alias maps to which server (e.g. "production", "staging/backup") is fine to keep
in memory/notes — it's not a secret, just a label. The `HostName`, `User`, and key
material themselves must stay only in `~/.ssh/config` and the local `~/.ssh/` key files.

## Safety rules when acting on a server

- **Read before you write.** Run status/inspect commands (`docker ps`, `docker inspect`,
  `df -h`) before anything destructive.
- **Confirm before anything destructive or service-affecting**: `docker rm`, `docker
  volume rm`, `docker system prune`, restarting a container, or editing files under
  `/data/coolify`. These affect a live, shared host — treat them like production changes.
- **Never touch resources Coolify doesn't manage** (containers/volumes without a
  `coolify.*` label or outside `/data/coolify`) without the user explicitly pointing at
  them — the host may run other things alongside Coolify.
- **Prefer the Coolify UI for structural changes** (creating a new application/service,
  changing its build/deploy config) — it keeps Coolify's own database in sync. Use SSH
  for inspection, troubleshooting, and operations Coolify's UI doesn't expose (ad-hoc
  volume creation, log tailing, disk cleanup).
