# Credentials

New Relic is reached over HTTPS (the NerdGraph API), not over SSH, so there is no host alias
to configure. The credentials are read from environment variables on the operator's machine.
None of them belong in a repository, a prompt, or persistent memory.

| Variable | What | Secret? |
| --- | --- | --- |
| `NEW_RELIC_API_KEY` | New Relic **User API key** (starts with `NRAK-`). Create it at one.newrelic.com → profile menu → *API keys* → *Create a key* → type *User*. | **Yes** |
| `NEW_RELIC_ACCOUNT_ID` | Numeric id of the account that owns the data. | No |
| `NEW_RELIC_REGION` | `eu` or `us`, the data centre of the account. EU accounts use `api.eu.newrelic.com`. Defaults to `eu`. | No |

Set them once in the environment the coding tool runs in, so every session on the machine has
them. How to do that per tool is described in `docs/cross-tool-compatibility.md` of the
marketplace repository.

## Fallback on macOS

If `NEW_RELIC_API_KEY` is not set, the query function in `querying.md` reads the key from the macOS Keychain
(service `newrelic-api-key`). Store it from a terminal, the `-w` at the end prompts for
the key so it never lands in shell history:

```bash
security add-generic-password -a "$USER" -s newrelic-api-key -w
```

## Rules

- Never ask the user to paste the key into the conversation and never print it. If it was
  pasted anyway, tell the user to rotate it.
- Never write it into a file that is committed (`.env`, scripts, settings, notes) or into
  persistent memory.
- Pass the key to `curl` through stdin (`-H @-`), as the function in `querying.md` does, so it
  does not appear in the process list or in the command text.
- The *license key* (`NEW_RELIC_LICENSE_KEY`, used by agents to send data) is a different
  thing from the User API key (used to read data). It lives in the hosting environment
  (for example Coolify) and is not needed to query.
