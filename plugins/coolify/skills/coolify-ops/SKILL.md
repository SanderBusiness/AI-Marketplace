---
name: coolify-ops
description: Operate self-hosted Coolify instances over SSH — check application and container status, inspect disk usage, create and manage Docker volumes, read deployment/proxy logs, and troubleshoot unhealthy resources. Load this when the user asks to check, deploy, restart, or debug something on a Coolify-managed server, or to create/inspect a volume or database on one.
---

Coolify is a self-hosted PaaS: it runs applications, databases, and services as Docker
containers/compose stacks on one or more servers, and fronts them with a proxy (Traefik
or Caddy) for routing and TLS. There is no official remote CLI — operate it either
through its web UI/API, or, as configured here, by SSH-ing directly into the host and
using `docker`.

Read only the reference file(s) relevant to the task at hand:

- **`references/connecting.md`** — how servers are reached (SSH host aliases in
  `~/.ssh/config`, never hardcoded IPs/keys) and safety rules for acting on a shared
  host. Load first, before running any command against a server.
- **`references/architecture.md`** — how Coolify lays out data on the host
  (`/data/coolify`), its Docker networks/labels, and how resources (application/service/
  database) map to containers and compose projects. Load when you need to find a
  resource's container, compose file, or persistent data on disk.
- **`references/docker-operations.md`** — commands for checking container/application
  status, disk and volume usage, creating a new volume tied to a resource, and reading
  logs. Load for day-to-day status checks and volume work.
- **`references/troubleshooting.md`** — common failure patterns (unhealthy container,
  stuck deployment, full disk, proxy not routing, permission errors on a volume) and how
  to diagnose each. Load when something is broken rather than just being checked on.
