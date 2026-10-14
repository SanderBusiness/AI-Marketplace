# Traces

Query and troubleshoot Traces (a self-hosted, OpenTelemetry-based observability platform that
replaces New Relic) from the terminal: read errors, requests, traces and logs, run NRQL,
manage dashboards, and set up OpenTelemetry instrumentation.

See `skills/traces-ops/SKILL.md`. Credentials (a personal Traces API token and the API base
URL) come from environment variables on the operator's machine, with a macOS Keychain
fallback for the token. They are never stored in this plugin or in a project repository. See
`docs/cross-tool-compatibility.md` for how to make the variables available to each tool.
