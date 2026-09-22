# Building on GitHub Actions, deploying with Coolify

A common way to run a Coolify-hosted app is to let Coolify clone the repo and build the
Dockerfile itself on the server. That works, but the build (npm install, a multi-stage
compile, etc.) competes with everything else running on the same host for CPU and
memory, right at deploy time.

The alternative: build the image on a GitHub Actions runner, push it to a **private**
GHCR (GitHub Container Registry) package, and have Coolify only ever pull and run the
already-built image. The server never builds anything itself.

## One-time server setup

The Coolify host needs its own Docker daemon authenticated to GHCR so it can pull
private images:

```
docker login ghcr.io -u <github-username>
```

Use a GitHub personal access token with `read:packages` scope as the password. This is
a one-time step per server — every application that pulls from a private GHCR package
on that host reuses this login. Nothing else (no per-application registry credential)
needs configuring in Coolify for this to work.

## The GitHub Actions workflow

One workflow per independently-deployable component (frontend, backend, each
microservice, ...), each restricted to the paths that actually affect it, so an
unrelated change doesn't rebuild and redeploy everything:

```yaml
name: Backend image

on:
  push:
    branches: [main]
    paths:
      - "backend/**"
      - ".github/workflows/backend-image.yml"
  workflow_dispatch:

env:
  # Hardcode lowercase — GHCR rejects uppercase, and github.repository_owner is NOT
  # lowercased automatically (an org/user name with capitals will break the push).
  IMAGE: ghcr.io/<owner-lowercase>/<image-name>

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          context: backend
          push: true
          tags: |
            ${{ env.IMAGE }}:${{ github.sha }}
            ${{ env.IMAGE }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
      - name: Trigger Coolify deploy
        env:
          COOLIFY_URL: ${{ secrets.COOLIFY_URL }}
          APPLICATION_UUID: ${{ secrets.COOLIFY_APPLICATION_UUID }}
          COOLIFY_API_TOKEN: ${{ secrets.COOLIFY_API_TOKEN }}
        run: |
          curl --fail --silent --show-error --request POST \
            --header "Authorization: Bearer $COOLIFY_API_TOKEN" \
            "$COOLIFY_URL/api/v1/deploy?uuid=$APPLICATION_UUID&force=false"
```

`GITHUB_TOKEN` (built-in, no setup needed) is enough to push to the repo's own GHCR
packages. The Coolify API token is a separate secret the operator creates in the
Coolify UI (Keys & Tokens) and adds as a repo/org secret — treat it like any other
deploy credential.

## Creating the Coolify application

An application that pulls a prebuilt image is created with `build_pack: dockerimage`.
Via the Coolify REST API:

```
POST /api/v1/applications/dockerimage
Authorization: Bearer <coolify-api-token>

{
  "project_uuid": "...",
  "server_uuid": "...",
  "environment_name": "production",
  "docker_registry_image_name": "ghcr.io/<owner>/<image>",
  "docker_registry_image_tag": "latest",
  "ports_exposes": "8080",
  "name": "my-app",
  "domains": "https://app.example.com",
  "instant_deploy": false
}
```

The response includes the new application's `uuid` — that's what the workflow's
`COOLIFY_APPLICATION_UUID` secret should be. This is a **structural change**, so the
same caution from `connecting.md` applies: it's a scripted equivalent of a UI action,
not a routine inspection command — review the payload before sending it, especially on
a shared/production server.

## Gotchas encountered in practice

- **You cannot convert an existing git-build application to `dockerimage` in place.**
  `PATCH /api/v1/applications/{uuid}` with `"build_pack": "dockerimage"` is rejected
  ("The selected build pack is invalid"), even though that's a valid value when
  *creating* an application. The working path is: `GET` the application and its `/envs`
  to capture domains, env vars (with real values), and healthcheck config; `DELETE` the
  old application; `POST .../applications/dockerimage` to recreate it; replay the env
  vars via `POST .../applications/{uuid}/envs`; then diff the restored env vars against
  the backup before doing anything else, to confirm nothing was lost.

- **`npm ci` needs a committed lockfile.** Some projects `.gitignore` their
  `package-lock.json`. If the Dockerfile uses `npm ci`, the build fails in CI with
  `"/package-lock.json": not found` even though it builds fine locally (where the
  ignored file still exists on disk). Either stop ignoring the lockfile, or use
  `npm install` in the Dockerfile instead.

- **Deployments queue serially per server.** Coolify runs one deployment at a time on a
  given server. Triggering several deploys in quick succession (e.g. migrating multiple
  apps back-to-back) queues them up; they resolve one after another over the next
  several minutes. A deployment sitting at `status: queued` for a minute or two isn't
  stuck — check back before assuming something is broken.

- **DNS must point at the server before a domain gets a cert.** Coolify (via Traefik)
  requests a Let's Encrypt certificate for an application's domain(s) on deploy. If DNS
  for that domain still resolves elsewhere (e.g. mid-migration from another host), ACME
  issuance fails and the app is reachable directly on the server but not over its public
  HTTPS domain yet. The application itself is running and healthy in this state — it's
  purely a DNS/cert timing issue, visible in the proxy container's logs as an ACME
  error.

- **A working Dockerfile can stop building for reasons unrelated to the deploy
  migration.** Long-EOL Docker Hub base images (e.g. `openjdk:*`) can be removed from
  the registry entirely. If a build that used to work on the old (git-build) deploy path
  suddenly fails to resolve its base image in CI, check whether the base image still
  exists before assuming the new pipeline is at fault; pin to a maintained equivalent.
