# How Coolify lays out a server

- **Coolify itself** runs as a set of containers (its own app, a Postgres/Redis pair,
  and — on the server it manages remotely — a lightweight `coolify-proxy` and helper
  containers) usually under the `coolify` Docker network.
- **Persistent data root**: `/data/coolify/` on the managed server. Under it:
  - `applications/<uuid>/` — build context and compose files for each deployed app.
  - `databases/<uuid>/` — data directories for Coolify-managed databases.
  - `services/<uuid>/` — compose-based services (e.g. Redis, MinIO, Plausible).
  - `backups/`, `ssh/`, `proxy/` — backup archives, the SSH key Coolify uses to manage
    the host, and proxy (Traefik/Caddy) config.
- **Every resource is a Docker Compose project.** Coolify generates a
  `docker-compose.yml` per application/service/database and deploys it with
  `docker compose`. The compose project name is normally the resource's short UUID, so
  `docker ps --filter name=<uuid>` or `docker compose -p <uuid> ps` scopes commands to
  one resource.
- **Labels**: Coolify-managed containers carry `coolify.managed=true` and related
  `coolify.*` labels (application/service/team/environment UUIDs), plus `traefik.*` (or
  Caddy) labels that drive routing. `docker inspect --format '{{json .Config.Labels}}'
  <container>` shows them — a quick way to confirm a container is Coolify's before
  touching it.
- **Networking**: each resource typically gets its own Docker network
  (`<uuid>_default` or similar) plus attachment to the shared `coolify` network so the
  proxy can reach it. Two containers on different resource networks can't talk to each
  other unless explicitly connected.
- **Volumes**: named volumes Coolify creates for persistent storage (databases,
  uploads) are prefixed with the resource UUID, e.g. `<uuid>_db-data`. Ad-hoc bind
  mounts often live directly under `/data/coolify/<kind>/<uuid>/`.
