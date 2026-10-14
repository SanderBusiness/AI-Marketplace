# Querying the Traces API

Call the REST API with `curl`. Define this shell function once per command (it reads the
credentials described in `credentials.md` and sends the token through stdin so it never
appears in the process list or in the command text):

```bash
traces() {  # traces PATH [JSON_BODY | @file]  -> GET, or POST when a body is given
  local key="${TRACES_API_TOKEN:-$(security find-generic-password -s traces-api-token -w 2>/dev/null)}"
  [ -n "$key" ] || { echo "Traces API token missing, see credentials.md" >&2; return 2; }
  local url="${TRACES_API_URL:-https://traces-api.sanderc.net}"
  local args=(-sS --max-time 60 -H @-)
  [ -n "$2" ] && args+=(-X POST --data-binary "$2")
  printf 'Authorization: Bearer %s\nContent-Type: application/json\n' "$key" |
    curl "${args[@]}" "${url%/}$1" |
    python3 -c 'import json,sys; t=sys.stdin.read(); print(json.dumps(json.loads(t),separators=(",",":"),ensure_ascii=False)) if t.strip() else print("(empty response)")'
}

traces /api/projects
```

A `401` means the token is missing, wrong or revoked (see `credentials.md`). Do not save this
function into a file in a project repository. Interactive API docs: `<TRACES_API_URL>/docs`.

Conventions: times are **Unix milliseconds** (`from`, `to`; default is the last 24 hours).
`$(( $(date +%s) * 1000 ))` is "now" and `$(( ($(date +%s) - 3600) * 1000 ))` is one hour ago.
Lists are newest first; page with `before=<nextCursor>` until `nextCursor` is null. Always
pass a small `limit` and a narrow window, and pipe through `python3` or `jq` to keep only
the fields you need.

```bash
NOW=$(( $(date +%s) * 1000 )); HOUR_AGO=$(( NOW - 3600000 ))
```

## Projects

```bash
traces /api/projects                 # [{id,name,description,role,createdAt}]
```

Resolve a project name to its id (the other endpoints need the GUID):

```bash
PID=$(traces /api/projects | python3 -c 'import json,sys; n=sys.argv[1].lower(); print(next((p["id"] for p in json.load(sys.stdin) if p["name"].lower()==n), ""))' "my-project")
```

## Overview of all projects

```bash
traces "/api/overview?from=$HOUR_AGO&to=$NOW"
# projects[]: id,name,requests,throughputRpm,errorRatePercent,p95Ms,errorGroups,errorEvents,pageViews,telemetryBytes,...
# recentErrors[]: project + error group
traces "/api/projects/$PID/services?from=$HOUR_AGO"   # per service: kind, requests, errorRatePercent, p50/p95/p99Ms, lastSeenMs
```

## Errors

Error groups cover span exceptions (`Trace`), error logs (`Log`) and browser JS errors
(`Browser`), ordered by occurrences.

```bash
traces "/api/projects/$PID/errors?from=$HOUR_AGO&to=$NOW"                       # groups[]: fingerprint,source,service,type,message,location,count,firstSeenMs,lastSeenMs
traces "/api/projects/$PID/errors?source=Trace&service=my-api&q=timeout"        # filters: service, source (Trace|Log|Browser), q (text)
traces "/api/projects/$PID/errors/<fingerprint>?from=$HOUR_AGO"                 # one group
```

The detail holds `stackTrace`, `attributes`, `affectedTraces`, a `timeline` and
`occurrences[]` (`timeMs`, `traceId`, `httpRoute`, `httpStatusCode`, `host`). Take a `traceId`
from there to open the whole request.

## Requests and traces

```bash
traces "/api/projects/$PID/traces?from=$HOUR_AGO&limit=20"                      # items[]: traceId,service,name,startMs,durationMs,httpMethod,httpRoute,httpStatusCode,isError,spanCount
traces "/api/projects/$PID/traces?errorsOnly=true&limit=20"
traces "/api/projects/$PID/traces?minDurationMs=1000&service=my-api&name=GET&limit=20"   # slow requests
traces "/api/projects/$PID/traces/<traceId>"                                    # spans[] (spanId,parentSpanId,service,name,startUs,durationUs,isError,exception*) + logs[]
```

Spans form a tree through `parentSpanId`; durations and starts of spans are microseconds.

## Logs

```bash
traces "/api/projects/$PID/logs?minSeverity=error&from=$HOUR_AGO&limit=50"      # items[]: id,time,severity,service,body,traceId,spanId,exception*
traces "/api/projects/$PID/logs?q=timeout&service=my-api&limit=50"              # q = case-insensitive substring of the body
traces "/api/projects/$PID/logs?traceId=<traceId>"                              # logs of one request
traces "/api/projects/$PID/logs?before=<nextCursor>&limit=50"                   # next (older) page
traces "/api/projects/$PID/logs/<id>"                                           # one record with attributes
```

`minSeverity` is 1-24 or `trace|debug|info|warn|error|fatal`.

## NRQL

`POST /api/query` runs NRQL across all projects you can access (or the ones in `projectIds`).
`from`/`to` (Unix ms) override the query's `SINCE`/`UNTIL`. Max 4000 characters; rate limited.

```bash
traces /api/query '{"nrql":"SELECT count(*) FROM Transaction SINCE 1 day ago"}'
traces /api/query "{\"nrql\":\"SELECT count(*) FROM TransactionError FACET error.message SINCE 1 hour ago LIMIT 20\",\"projectIds\":[\"$PID\"]}"
traces /api/query/schema            # event types and their attributes (no token needed)
```

Result: `kind`, `columns[]` (`name`, `kind` facet|value), `rows[][]`, or `series[]`
(`label`, `facets`, `points[]` of `{t,v}`) for `TIMESERIES`; `truncated` tells if the scan limit was hit.

Supported syntax: `SELECT … FROM … [WHERE] [FACET (max 3)] [LIMIT n|MAX] [TIMESERIES n units|AUTO|MAX] [SINCE] [UNTIL]`.
Functions: `count`, `uniqueCount`, `sum`, `average`, `min`, `max`, `median`, `percentile(attr, n)`
(one percentile per call), `latest`, `earliest`, `rate(agg, 1 minute)`, `percentage(agg, WHERE …)`,
`filter(agg, WHERE …)`, with `AS` aliases and arithmetic. Conditions: `= != < <= > >=`, `LIKE`, `IN`,
`IS [NOT] NULL|TRUE|FALSE`, `AND`/`OR`/`NOT`. Time: `SINCE 1 hour ago`, `'2026-01-31 08:00:00'`, `today`,
`yesterday`, `now`, epoch ms. Only aggregate queries work (no raw `SELECT attr FROM …` or `SELECT *`): use the logs and traces endpoints for individual records. Not supported: `FACET CASES`, `COMPARE WITH`, `EXTRAPOLATE`, `SLIDE BY`,
several percentiles in one `percentile()`.

Event types and the most useful attributes (many New Relic names are accepted as aliases):

| Event type | Attributes |
| --- | --- |
| `Transaction` (entry spans = requests) | `appName`, `name`/`transactionName`, `duration` (seconds), `http.statusCode`, `request.method`, `request.uri`/`http.route`, `error.class`, `error.message`, `host`, `project` |
| `TransactionError` | same as `Transaction`, only spans with an error |
| `Span` | all spans; adds `span.kind`, `nr.entryPoint`, `otel.library.name` |
| `Log` | `appName`, `message`, `level` (FATAL, ERROR, WARN, INFO, DEBUG, TRACE), `severity.number`, `logger`, `error.class`, `error.message`, `host` |
| `JavaScriptError` | browser error logs: same attributes as `Log` |
| `PageView` | `appName`, `session`, `duration`, `timeToFirstByte`, `pageUrl`, `countryCode`, `regionCode`, `deviceType`, `userAgentOS`, `userAgentName` |
| `BrowserInteraction` | like `PageView` but also route changes; `category` is `initialPageLoad` or `routeChange` |
| `PageViewTiming` / `WebVital` | `name` (LCP, INP, CLS, FCP, TTFB), `value`, `rating` (good, needs-improvement, poor), `largestContentfulPaint`, `interactionToNextPaint`, `pageUrl`, `deviceType` |
| `Metric` | `metricName`, `appName`, `host.name`, `container.name`, `project`, plus any metric name or attribute as a column, e.g. `average(system.cpu.utilization)` |

```sql
SELECT count(*) FROM TransactionError FACET error.message, transactionName SINCE 1 hour ago LIMIT 20
SELECT average(duration), percentile(duration, 95), count(*) FROM Transaction FACET name SINCE 1 hour ago LIMIT 20
SELECT count(*) FROM Transaction FACET http.statusCode SINCE 1 hour ago
SELECT rate(count(*), 1 minute) FROM Transaction TIMESERIES SINCE 3 hours ago
SELECT count(*) FROM Log WHERE level IN ('ERROR','FATAL') FACET appName, message SINCE 30 minutes ago LIMIT 20
SELECT count(*) FROM JavaScriptError FACET message, appName SINCE 1 day ago LIMIT 20
SELECT percentile(largestContentfulPaint, 75) FROM PageViewTiming FACET pageUrl SINCE 1 day ago LIMIT 20
SELECT average(system.cpu.utilization) FROM Metric FACET host.name TIMESERIES SINCE 3 hours ago
SELECT count(*), latest(duration) FROM Transaction FACET appName SINCE 1 day ago   -- which apps report
```

## Dashboards

```bash
traces /api/dashboards                    # list: id, name, ...
traces /api/dashboards/templates          # built-in dashboards in New Relic JSON format
traces /api/dashboards/<id>               # one dashboard definition
```

Importing a New Relic dashboard JSON (or a template) creates a dashboard in the user's account:
**confirm first**. The body is the dashboard JSON itself (at most 256 KB):

```bash
traces /api/dashboards @dashboard.json    # POST; the function passes the "@file" to curl --data-binary
```

`GET /api/dashboards/<id>/export` downloads the JSON again (importable into New Relic). Updating
(`PUT`), duplicating, and deleting (`DELETE`) dashboards change the account: confirm first, and
use `curl` directly with the same stdin-header pattern as the function above.

## Reporting back

Say what you queried, the time window, and what you found in two or three sentences; quote
only the decisive error line or stack frame. If a query returns nothing, say so and check
that data is arriving (`references/instrumentation.md`) before drawing conclusions.
