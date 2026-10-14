# Instrumentation

Applications send data to Traces with standard OpenTelemetry (OTLP over HTTP). Nothing
Traces-specific is installed in the application.

- Endpoint: `<TRACES_API_URL>/v1/traces`, `/v1/logs`, `/v1/metrics` (default API URL
  `https://traces-api.sanderc.net`, or the self-hosted one).
- Auth: header `x-traces-key: trc_…`, a **project ingest key** from *Project* › *Settings* in
  Traces. One key belongs to one project. It is not the `trcu_…` API token used for reading.
  Keep it in the hosting environment (for example the platform's environment variables),
  never in the repository.

Environment variables understood by every OpenTelemetry SDK and agent:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=https://traces-api.sanderc.net
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_EXPORTER_OTLP_HEADERS=x-traces-key=<YOUR_INGEST_KEY>
OTEL_SERVICE_NAME=my-service
```

## .NET backend

```bash
dotnet add package OpenTelemetry.Extensions.Hosting
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
dotnet add package OpenTelemetry.Instrumentation.Http
dotnet add package OpenTelemetry.Instrumentation.SqlClient   # or OpenTelemetry.Instrumentation.EntityFrameworkCore
dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol
```

`Program.cs`:

```csharp
builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r.AddService("my-service"))
    .WithTracing(t => t
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSqlClientInstrumentation())
    .WithMetrics(m => m
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation())
    .UseOtlpExporter();

builder.Logging.AddOpenTelemetry(o =>
{
    o.IncludeFormattedMessage = true;
    o.IncludeScopes = true;
});
```

Send logs at Warning and above only (storage is limited): in `appsettings.json` set
`"Logging": { "LogLevel": { "Default": "Warning" } }` or, to keep console logging as is, add
`"OpenTelemetry": { "LogLevel": { "Default": "Warning" } }`. Set the four environment variables
above on the runtime environment.

## Java

Use the OpenTelemetry Java agent; no code changes:

```bash
curl -L -O https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
# set the four environment variables, then
java -javaagent:opentelemetry-javaagent.jar -jar app.jar
```

## Python

```bash
pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install
# set the four environment variables, then
opentelemetry-instrument python app.py
```

## Browser

Add the script tag to the page (it sends page views, web vitals and JavaScript errors).
`data-key` is the project ingest key; it is public by design in a browser page, so use a
key of its own for the frontend.

```html
<script src="https://traces-api.sanderc.net/browser/traces.js"
        data-endpoint="https://traces-api.sanderc.net"
        data-key="<YOUR_INGEST_KEY>"
        data-service="my-service frontend" async></script>
```

If the site shows a cookie banner, load the script only after consent:

```js
function onCookieConsentGranted() {
  const s = document.createElement('script')
  s.src = 'https://traces-api.sanderc.net/browser/traces.js'
  s.async = true
  s.dataset.endpoint = 'https://traces-api.sanderc.net'
  s.dataset.key = '<YOUR_INGEST_KEY>'
  s.dataset.service = 'my-service frontend'
  document.head.appendChild(s)
}
```

## Servers (host and container metrics)

Run an OpenTelemetry Collector (contrib distribution) on the Docker host with the
`hostmetrics` receiver (CPU, memory, load, filesystems, disk I/O, network, paging) and the
`docker_stats` receiver (per-container CPU, memory, network, block I/O), exporting OTLP/HTTP
metrics to `<TRACES_API_URL>` with the `x-traces-key` header, every 60 s. Set `host.name`
so the server is recognisable. The collector needs read access to `/var/run/docker.sock`
(the docker group id). By design there are no process metrics and no container log tailing,
to keep storage low; ship application logs through the application's own SDK instead.

## Verify that data arrives

Within a minute or two of traffic (see `querying.md` for the `traces` function):

```bash
traces /api/overview                                   # the project shows requests / telemetry bytes
traces /api/query '{"nrql":"SELECT count(*) FROM Transaction FACET appName SINCE 1 day ago"}'
traces /api/query '{"nrql":"SELECT count(*) FROM Log SINCE 1 hour ago"}'
traces /api/query '{"nrql":"SELECT count(*) FROM PageView SINCE 1 hour ago"}'      # browser
traces /api/query '{"nrql":"SELECT latest(system.cpu.utilization) FROM Metric FACET host.name SINCE 10 minutes ago"}'   # servers
```

## Common causes when data is missing

1. ingest key missing, revoked, or for another project (export errors with 401/403 in the app log)
2. endpoint wrong: the OTLP exporter appends `/v1/traces` itself when you use
   `OTEL_EXPORTER_OTLP_ENDPOINT`; do not add the path, and use `http/protobuf`
3. the service is not receiving traffic in the window
4. only logs missing: the log level is below Warning, or the logging provider is not added
5. browser: script blocked by cookie consent or CSP, or `data-key`/`data-endpoint` missing
6. the project hit its storage limit (see `telemetryBytes` vs `telemetryLimitBytes` in the overview)

## Migrating from New Relic

1. Add the OpenTelemetry instrumentation above and confirm data arrives.
2. Remove the New Relic agent: the Dockerfile lines that download the .NET agent, and the
   environment variables `CORECLR_ENABLE_PROFILING`, `CORECLR_PROFILER`,
   `CORECLR_PROFILER_PATH`, `CORECLR_NEWRELIC_HOME`, `NEW_RELIC_APP_NAME`,
   `NEW_RELIC_LICENSE_KEY`, `NEW_RELIC_HOST` (and `-javaagent:newrelic.jar` for Java). Remove the
   browser snippet and its `VITE_NEW_RELIC_*` variables.
3. On servers, stop the infrastructure agent once the collector reports:
   `systemctl stop newrelic-infra && apt-get remove --purge newrelic-infra`.
4. Dashboards: NRQL dashboards import as-is. Export the dashboard JSON from New Relic and
   import it (`POST /api/dashboards`, see `querying.md`); attribute names such as
   `appName`, `transactionName` and `duration` are understood.
