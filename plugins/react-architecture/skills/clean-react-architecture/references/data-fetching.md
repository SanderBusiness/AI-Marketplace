# Data fetching

**Rule: components never call `fetch`. All server data goes through typed TanStack Query hooks
exported from `src/api/<feature>.ts`.**

## One API file per backend controller/feature

`src/api/projects.ts` for `/api/projects`, `src/api/errors.ts` for `/api/errors`, and so on.
Each file exports, in this order: **types** (or imports them from a feature types file),
**query keys**, **request functions**, **hooks**. `src/api/client.ts` is transport only.

```ts
// api/projects.ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from './client'

export type Project = { id: string; name: string; archived: boolean }
export type ProjectInput = { name: string }

export const projectKeys = {
  all: ['projects'] as const,
  list: (search: string) => ['projects', 'list', { search }] as const,
  detail: (id: string) => ['projects', 'detail', id] as const,
}

export const projectsApi = {
  list: (search: string, signal?: AbortSignal) =>
    api.get<Project[]>('/api/projects', { query: { search: search || undefined }, signal }),
  get: (id: string) => api.get<Project>(`/api/projects/${id}`),
  create: (body: ProjectInput) => api.post<Project>('/api/projects', body),
}

export function useProjects(search: string) {
  return useQuery({
    queryKey: projectKeys.list(search),
    queryFn: ({ signal }) => projectsApi.list(search, signal),
    placeholderData: keepPreviousData,
  })
}

export function useCreateProject() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: projectsApi.create,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: projectKeys.all }),
  })
}
```

- One key factory per feature, exported, hierarchical (`['projects', 'list', ...]`) so one
  invalidation of the root refreshes the feature. A single central `queryKeys.ts` also works
  for small apps; prefer keys next to their hooks so a feature is one file.
- Pass `signal` through so superseded requests are cancelled.
- Put `staleTime` / `placeholderData` choices in the hook, not the component.
- Hand-rolled `useEffect` + `useState` fetch hooks (`useHttp`, `useAsyncData`) are what this
  replaces; they re-implement caching, cancellation and races badly.

## `client.ts`: transport, errors, session

```ts
/** RFC 7807 problem details. */
export type ProblemDetails = { type?: string; title?: string; status?: number; detail?: string; errors?: Record<string, string[]> }

/** Every failed call throws this. status 0 = network unreachable. */
export class ApiError extends Error {
  constructor(readonly status: number, readonly title: string, opts: { detail?: string; errors?: Record<string, string[]> } = {}) {
    super(title); this.name = 'ApiError'
    this.detail = opts.detail; this.errors = opts.errors ?? {}
  }
  readonly detail?: string
  readonly errors: Record<string, string[]>
  get isNetworkError() { return this.status === 0 }
  fieldError(field: string) {
    const key = Object.keys(this.errors).find((k) => k.toLowerCase() === field.toLowerCase())
    return key ? this.errors[key]?.[0] : undefined
  }
}
```

`apiFetch<T>(path, { method, body, query, signal, anonymous })` builds the URL (skipping
`undefined` query values), sets `Accept`/`Content-Type`, attaches the bearer token, maps
non-2xx to `ApiError` (parse problem details; tolerate non-JSON bodies), maps `fetch`
failures to `ApiError(0, ...)`, returns `undefined` for 204. Expose `api.get/post/put/patch/delete`.

## Auth: token in memory, refresh cookie HttpOnly

- The **access token lives only in module memory**, never in localStorage. The refresh token
  is an **HttpOnly cookie** (`credentials: 'include'`), so a reload restores the session
  through a silent refresh.
- On a 401, refresh **once** and retry; concurrent requests **share one refresh promise**:

```ts
let refreshPromise: Promise<Session | null> | null = null
export function refreshSession() {
  refreshPromise ??= (async () => {
    try {
      const res = await safeFetch(apiUrl('/api/auth/refresh'), { method: 'POST' })
      if ([400, 401, 403].includes(res.status)) { setSession(null); return null }
      if (!res.ok) throw await toApiError(res)   // network/5xx must not log the user out
      const data = (await res.json()) as AuthResponse
      setSession(data)
      return data
    } finally { refreshPromise = null }
  })()
  return refreshPromise
}
```

- `subscribeSession(listener)` lets `AuthProvider` mirror session changes into React state.
- On logout: `queryClient.clear()` and drop any cached API data.
- Use a same-origin `/api` (Vite dev proxy, reverse proxy in production): no CORS, cookie just works.

## Query client defaults

Do not retry 4xx; retry others twice; `networkMode: 'online'`; mutations never retry.
Turn `ApiError` into text with one pure function (`errorMessage(error)`) used by every error view.
