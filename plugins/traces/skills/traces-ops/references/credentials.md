# Credentials

Traces is reached over HTTPS (its REST API), not over SSH, so there is no host alias to
configure. The credentials are read from environment variables on the operator's machine.
None of them belong in a repository, a prompt, or persistent memory.

| Variable | What | Secret? |
| --- | --- | --- |
| `TRACES_API_TOKEN` | Personal Traces **API token** (starts with `trcu_`). Create it in Traces under *Account* › *API tokens*. | **Yes** |
| `TRACES_API_URL` | Base URL of the Traces API. Defaults to `https://traces-api.sanderc.net` (the public hosted instance); self-hosters set their own. | No |

Set them once in the environment the coding tool runs in, so every session on the machine has
them. How to do that per tool is described in `docs/cross-tool-compatibility.md` of the
marketplace repository.

## Fallback on macOS

If `TRACES_API_TOKEN` is not set, the `traces` function in `querying.md` reads the token from
the macOS Keychain (service `traces-api-token`). Store it from a terminal, the `-w` at the
end prompts for the token so it never lands in shell history:

```bash
security add-generic-password -a "$USER" -s traces-api-token -w
```

## Rules

- Never ask the user to paste the token into the conversation and never print it. If it was
  pasted anyway, tell the user to revoke it under *Account* › *API tokens* and create a new one.
- Never write it into a file that is committed (`.env`, scripts, settings, notes) or into
  persistent memory.
- Pass the token to `curl` through stdin (`-H @-`), as the function in `querying.md` does, so
  it does not appear in the process list or in the command text.
- The *ingest key* (`trc_…`, used by applications to send data, see `instrumentation.md`) is a
  different thing from the API token (`trcu_…`, used to read data). Ingest keys belong to one
  project and live in the hosting environment of the application; they are not needed to query.
