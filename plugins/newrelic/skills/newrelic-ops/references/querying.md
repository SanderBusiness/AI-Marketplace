# Querying with NRQL

Run NRQL through the NerdGraph API with `curl`. Define this shell function once per command
(it reads the credentials described in `credentials.md` and sends the key through stdin so it
never appears in the process list or in the command text):

```bash
nrql() {
  local key="${NEW_RELIC_API_KEY:-$(security find-generic-password -s newrelic-api-key -w 2>/dev/null)}"
  [ -n "$key" ] && [ -n "$NEW_RELIC_ACCOUNT_ID" ] || { echo "New Relic credentials missing, see credentials.md" >&2; return 2; }
  local host=api.eu.newrelic.com
  [ "$(echo "${NEW_RELIC_REGION:-eu}" | tr A-Z a-z)" = us ] && host=api.newrelic.com
  local payload
  payload=$(python3 -c 'import json,sys; print(json.dumps({"query": "query($id: Int!, $q: Nrql!) { actor { account(id: $id) { nrql(query: $q) { results } } } }", "variables": {"id": int(sys.argv[1]), "q": sys.argv[2]}}))' "$NEW_RELIC_ACCOUNT_ID" "$1")
  printf 'API-Key: %s\nContent-Type: application/json\n' "$key" |
    curl -sS --max-time 60 -H @- -d "$payload" "https://$host/graphql" |
    python3 -c 'import json,sys; d=json.load(sys.stdin); e=d.get("errors"); print("New Relic error: "+"; ".join(x.get("message","?") for x in e)) if e else print(json.dumps(d["data"]["actor"]["account"]["nrql"]["results"], indent=2, ensure_ascii=False))'
}

nrql "SELECT count(*) FROM TransactionError FACET error.message SINCE 1 hour ago LIMIT 20"
```

An EU account queried on the US endpoint (or the other way round) answers `not authorized for
account region`: set `NEW_RELIC_REGION`. Do not save this function into a file in a project
repository.

Always include `SINCE` and, for raw events, `LIMIT`. Start narrow, widen only if needed.

## Errors

```sql
-- what is failing, grouped
SELECT count(*) FROM TransactionError FACET error.message, transactionName SINCE 1 hour ago LIMIT 20

-- one endpoint
SELECT timestamp, error.class, error.message, request.uri, http.statusCode
FROM TransactionError WHERE request.uri LIKE '%Events/Types%' SINCE 1 hour ago LIMIT 20

-- stack trace of the latest one
SELECT stack_trace, error.message FROM ErrorTrace WHERE `request.uri` LIKE '%Events/Types%' SINCE 1 day ago LIMIT 1
```

## Logs (needs *Logs in context* / log forwarding enabled)

```sql
SELECT timestamp, level, message FROM Log WHERE message LIKE '%Unhandled exception%' SINCE 1 hour ago LIMIT 50
SELECT timestamp, message FROM Log WHERE level = 'ERROR' SINCE 30 minutes ago LIMIT 50
-- around a moment
SELECT timestamp, level, message FROM Log SINCE '2026-09-26 08:20:00' UNTIL '2026-09-26 08:30:00' LIMIT 200
```

If `Log` returns nothing, log forwarding is not on; fall back to `TransactionError` or read the
container log on the host.

## Performance and traffic

```sql
SELECT average(duration), percentile(duration, 95), count(*) FROM Transaction FACET name SINCE 1 hour ago LIMIT 20
SELECT count(*) FROM Transaction FACET http.statusCode SINCE 1 hour ago
SELECT rate(count(*), 1 minute) FROM Transaction TIMESERIES SINCE 3 hours ago
```

## Browser (frontend agent)

```sql
SELECT count(*) FROM JavaScriptError FACET errorMessage, pageUrl SINCE 1 day ago LIMIT 20
SELECT count(*) FROM AjaxRequest WHERE httpResponseCode >= 400 FACET requestUrl, httpResponseCode SINCE 1 day ago LIMIT 20
SELECT average(duration) FROM PageView FACET pageUrl SINCE 1 day ago LIMIT 20
```

## Deployments and health

```sql
SELECT * FROM Deployment SINCE 1 week ago LIMIT 10     -- only if deployment markers are sent
SELECT uniques(appName) FROM Transaction SINCE 1 day ago  -- which apps report
SELECT latest(timestamp) FROM Transaction FACET appName  -- last time each app sent data
```

## Reporting back

Say what you queried, the time window, and what you found in two or three sentences; quote
only the decisive error line. If a query returns nothing, say so and check the agent
(`references/instrumentation.md`) before drawing conclusions.
