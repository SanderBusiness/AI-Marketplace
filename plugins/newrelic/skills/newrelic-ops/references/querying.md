# Querying with NRQL

Run any NRQL query:

```bash
scripts/nrql.sh "<NRQL>"            # prints JSON results
scripts/nrql.sh --table "<NRQL>"    # prints a compact table (needs python3)
```

Exit codes: 0 ok, 2 credentials missing, 3 New Relic returned an error (message printed).
The script defaults to the EU region and to `NEW_RELIC_ACCOUNT_ID`.

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
