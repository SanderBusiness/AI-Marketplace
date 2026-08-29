# Troubleshooting Coolify-managed resources

## Container unhealthy or restarting in a loop

1. `docker ps -a` — check restart count and status.
2. `docker logs --tail 100 <container>` — the crash reason is almost always here.
3. `docker inspect --format '{{json .State.Health}}' <container>` — if a healthcheck is
   defined, see what it's actually failing (often a wrong port or a slow startup vs a
   too-short `start_period`).

## Deployment stuck or failed in the Coolify UI

- Check the build/deploy log in the UI first — it's more complete than anything on disk.
- On the host: `docker ps -a --filter label=coolify.applicationId=<uuid>` to see if a
  build container is still running or exited with an error.
- Leftover build containers/images from a failed deploy: `docker image prune -f` after
  confirming nothing needed is being removed.

## Disk full / running low

This is the most recurring Coolify issue on these servers, and the recurring root
cause is **Docker image/build-cache bloat**, not application data — every deploy
builds a new image and leaves the old one behind, so unpruned hosts fill up steadily
over weeks even with no traffic growth. Diagnose in this order:

1. `df -h /data/coolify` and `docker system df` — `docker system df` breaks usage down
   by images / containers / local volumes / build cache, so it tells you which bucket
   is actually the problem before you guess.
2. If **images** or **build cache** dominate (the common case here):
   - `docker image prune -a -f` — removes *all* images not used by a running
     container. Safe on a Coolify host since it rebuilds from source on next deploy,
     but confirm nothing stopped-but-wanted depends on an old image first.
   - `docker builder prune -f` — clears the BuildKit cache, usually the single
     biggest reclaimable chunk after repeated deploys.
   - Run both together periodically (e.g. a cron job) rather than only reactively,
     since this refills continuously as deploys happen.
3. If **local volumes** dominate instead: check database volumes with `docker exec`
   into the DB (never delete a volume to "fix" this) — could be genuine data growth,
   not bloat.
4. Coolify's own backups under `/data/coolify/backups/` can also grow unbounded if
   retention isn't configured — check there before assuming it's application data.

## Proxy not routing to an application (502/504, wrong domain)

1. Confirm the container is actually running and healthy first (see above) — a routing
   error is often really a crashed backend.
2. `docker logs coolify-proxy --tail 100` (Traefik/Caddy container name may differ) for
   routing errors.
3. `docker inspect --format '{{json .Config.Labels}}' <container>` — check the
   `traefik.http.routers.*` labels match the expected domain and that the container is
   attached to the shared `coolify` network Traefik watches.
4. DNS/TLS issues (Let's Encrypt) show up in the proxy's own logs, not the app's.

## Permission errors on a bind-mounted volume

- Coolify often mounts host paths under `/data/coolify/...` into containers running as a
  non-root user. `ls -la` the host path and compare the owning UID/GID to
  `docker inspect --format '{{.Config.User}}' <container>` — mismatches are the usual
  cause. Fix with `chown` on the host path, not by changing the container's user.
