#!/usr/bin/env bash
# Run an NRQL query through NerdGraph. Usage: nrql.sh [--table] "<NRQL>"
# Credentials: NEW_RELIC_API_KEY or the Keychain item "newrelic-api-key"; NEW_RELIC_ACCOUNT_ID; NEW_RELIC_REGION (eu|us, default eu).
set -euo pipefail

table=0
if [[ "${1:-}" == "--table" ]]; then table=1; shift; fi
query="${1:-}"
[[ -n "$query" ]] || { echo "Usage: nrql.sh [--table] \"<NRQL>\"" >&2; exit 64; }

key="${NEW_RELIC_API_KEY:-}"
if [[ -z "$key" ]] && command -v security >/dev/null 2>&1; then
  key="$(security find-generic-password -s newrelic-api-key -w 2>/dev/null || true)"
fi
account="${NEW_RELIC_ACCOUNT_ID:-}"
if [[ -z "$key" || -z "$account" ]]; then
  echo "New Relic credentials missing (api key: ${key:+set}${key:-missing}, account id: ${account:-missing})." >&2
  echo "See references/credentials.md for the one-time setup." >&2
  exit 2
fi

region="$(echo "${NEW_RELIC_REGION:-eu}" | tr '[:upper:]' '[:lower:]')"
if [[ "$region" == "eu" ]]; then url="https://api.eu.newrelic.com/graphql"; else url="https://api.newrelic.com/graphql"; fi

payload="$(python3 - "$account" "$query" <<'PY'
import json, sys
account, nrql = sys.argv[1], sys.argv[2]
gql = "query($id: Int!, $nrql: Nrql!) { actor { account(id: $id) { nrql(query: $nrql) { results } } } }"
print(json.dumps({"query": gql, "variables": {"id": int(account), "nrql": nrql}}))
PY
)"

# The key goes through stdin (-H @-) so it never appears in the process list.
response="$(printf 'API-Key: %s\nContent-Type: application/json\n' "$key" | curl -sS --max-time 60 -H @- -d "$payload" "$url")"

printf '%s' "$response" | python3 -c '
import json, sys
table = sys.argv[1] == "1"
data = json.load(sys.stdin)
if data.get("errors"):
    print("New Relic error: " + "; ".join(e.get("message", "?") for e in data["errors"]), file=sys.stderr)
    sys.exit(3)
rows = data["data"]["actor"]["account"]["nrql"]["results"]
if not table:
    print(json.dumps(rows, indent=2, ensure_ascii=False))
    sys.exit(0)
if not rows:
    print("(no results)")
    sys.exit(0)
cols = list(rows[0].keys())
widths = [min(60, max(len(c), *(len(str(r.get(c, ""))) for r in rows))) for c in cols]
print("  ".join(c.ljust(w) for c, w in zip(cols, widths)))
for r in rows:
    print("  ".join(str(r.get(c, ""))[:w].ljust(w) for c, w in zip(cols, widths)))
' "$table"
