# Project layout

Group by **kind** for shared code, by **feature** for page-specific code. Generic building
blocks go in `components/common`; a component used by one page lives next to that page.

```
src/
  main.tsx              # mounts <App />
  AppProviders.tsx      # theme, query client, router, auth — nothing else
  AppRoutes.tsx         # route table, lazy-loaded pages
  config.ts             # reads import.meta.env once (apiUrl, ...)
  api/                  # THE data layer — one module per backend controller/feature
    client.ts           # transport only: apiFetch, ApiError, session/refresh
    queryClient.ts      # createQueryClient() (retry rules, staleTime)
    projects.ts         # types + requests + query keys + hooks for /api/projects
    errors.ts           # types + requests + hooks for /api/errors
    errorMessage.ts     # pure: ApiError -> user-facing text
  auth/                 # AuthProvider, useAuth, route guards
  components/
    common/             # generic, prop-driven: PageHeader, States, StatusChip, ...
  charts/               # the only place that imports the chart library
  theme/                # palette tokens, theme, provider
  time/                 # feature-wide hooks + pure helpers (useTimeRange, timeRange.ts)
  hooks/                # generic hooks (useOnline, useDebouncedValue)
  utils/                # pure functions (format.ts, initials.ts)
  layout/               # app shell, navigation
  pages/
    ProjectsPage.tsx
    projects/           # components used only by ProjectsPage
      ProjectCard.tsx
      useProjectFilters.ts
  test/                 # helpers.tsx (render wrappers), media.ts
```

## One API module per backend controller

Mirror the backend: one controller or feature = one file in `src/api/`, named after it
(`projects.ts`, `errors.ts`, `dashboards.ts`). Each module exports its **types, request
functions, query keys and query hooks**. `client.ts` knows nothing about any endpoint.
See `data-fetching.md`.

- Types live next to the feature that owns them. Only truly shared DTOs go in
  `api/types.ts` (a small project may keep all DTOs there; split once it passes ~300 lines).
- Cross-feature cache invalidation goes through exported keys, not copied key arrays.

## Rules

- `pages/` compose; they hold routing, URL state and layout, not business logic.
- Features do not import from each other's page folders; shared code moves to `components/common`,
  `hooks/` or `utils/`.
- Name files after their one export: `StatusChip.tsx`, `useTimeRange.ts`, `format.ts`.
- Tests sit next to the file they test (`client.ts` / `client.test.ts`).
- Magic strings used twice (route paths, storage keys, param names) become a named constant.
- Next.js (SSR/SEO sites) follows the same ideas under `src/app`, `src/components`, `src/lib`;
  use it only when server rendering is actually needed. Prefer Vite for apps behind a login.
