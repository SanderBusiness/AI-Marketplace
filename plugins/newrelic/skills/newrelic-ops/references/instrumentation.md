# Instrumentation

## .NET backend (APM agent)

- The agent is installed in the container image (Dockerfile downloads the .NET agent and
  sets `CORECLR_ENABLE_PROFILING`, `CORECLR_PROFILER`, `CORECLR_PROFILER_PATH`,
  `CORECLR_NEWRELIC_HOME`, `NEW_RELIC_APP_NAME`).
- The license key is **not** in the image. It must exist as the runtime environment variable
  `NEW_RELIC_LICENSE_KEY` on the host (for Coolify: application → Environment variables).
  Without it the agent starts but sends nothing.
- Region: EU accounts also need `NEW_RELIC_HOST=collector.eu01.nr-data.net` when the license
  key is an EU key and the agent does not pick it up by itself.
- Check data is arriving: `SELECT latest(timestamp) FROM Transaction FACET appName SINCE 1 day ago`.

## Browser agent (frontend)

- The snippet in `index.html` only runs when all three Vite variables are set at build
  time: `VITE_NEW_RELIC_LICENSE_KEY`, `VITE_NEW_RELIC_APPLICATION_ID`,
  `VITE_NEW_RELIC_ACCOUNT_ID`. If one is missing or contains a `%`, it silently skips.
- Beacon host for EU: `bam.eu01.nr-data.net`. A CORS error on that host in the browser
  console means the page's origin is not on the account's allowed origins; it does not break
  the app.
- Check data is arriving: `SELECT count(*) FROM PageView SINCE 1 hour ago`.

## Common causes when data is missing

1. license key missing or for the wrong region
2. account id / application id mismatch between the snippet and the account
3. the service is not receiving traffic in the window
4. log forwarding not enabled (only `Log` is empty, APM works)
5. querying the wrong region: EU accounts on the US endpoint return nothing (set `NEW_RELIC_REGION=eu`)
