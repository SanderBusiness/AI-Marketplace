# New Relic

Query and troubleshoot New Relic from the terminal: read application logs and errors, run
NRQL, check APM and browser data, and verify the agents are set up.

See `skills/newrelic-ops/SKILL.md`. Credentials (a New Relic User API key, account id and
region) come from environment variables on the operator's machine, with a macOS Keychain
fallback for the key. They are never stored in this plugin or in a project repository. See
`docs/cross-tool-compatibility.md` for how to make the variables available to each tool.
