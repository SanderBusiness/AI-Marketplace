# Day-to-day Docker operations on a Coolify server

Run these over SSH: `ssh <alias> '<command>'`. See `references/connecting.md` for
aliases and safety rules.

## Status checks

```sh
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'   # what's running, and its health
docker ps -a --filter status=exited                              # crashed/stopped containers
docker inspect --format '{{.State.Health.Status}}' <container>   # healthcheck result
docker compose -p <uuid> ps                                      # containers for one resource
```

## Logs

```sh
docker logs --tail 200 -f <container>          # follow recent logs
docker compose -p <uuid> logs --tail 200 -f     # follow all containers of one resource
```

## Disk and resource usage

```sh
df -h /data/coolify                # disk space on the Coolify data root
docker system df                   # images/containers/volumes/build-cache breakdown
docker stats --no-stream           # live CPU/memory per container
```

## Volumes

```sh
docker volume ls                                   # all volumes
docker volume inspect <name>                        # mountpoint, labels, driver
docker volume create <name>                          # ad-hoc volume, not tracked by Coolify's UI
```

A volume created this way (outside the Coolify UI) won't show up in Coolify's dashboard
and won't be included in Coolify's backup/restore flow. Prefer adding persistent storage
through the application/service's "Storage" tab in the Coolify UI when it needs to be
managed long-term; use `docker volume create` for genuinely ad-hoc/manual needs, and
tell the user it's UI-invisible.

## Restarting a resource

```sh
docker compose -p <uuid> restart          # restart all containers of one resource
docker restart <container>                # restart a single container
```

Prefer restarting through the Coolify UI ("Restart" on the resource) when possible — it
re-applies Coolify's current config; a raw `docker compose restart` just restarts the
containers as currently deployed.

## Cleanup

```sh
docker image prune -f                 # remove dangling images
docker system prune -f --volumes      # aggressive: also removes unused volumes — confirm first
```

Never run `docker system prune` on a Coolify host without checking what it will remove
first (`docker system df`, then prune without `-f` to see the confirmation prompt) —
it can delete volumes for stopped-but-wanted resources.
