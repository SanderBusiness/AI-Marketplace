# State and URLs

Pick the lightest state that works, in this order: **URL, props/derived values, local
`useState`, TanStack Query cache, context**. No global store library by default.

## URL as state

Anything a user would want to share or come back to (search text, filters, sort, tab, time
range, selected id) lives in the query string, not `useState`.

```ts
export function useTimeRange() {
  const [params, setParams] = useSearchParams()
  const range = params.get('range') ?? DEFAULT_RANGE            // '24h' or '<fromMs>-<toMs>'
  const window = useMemo(() => resolveRange(range, now), [range, minuteTick])
  const setRange = useCallback((next: string) =>
    setParams((current) => {
      const copy = new URLSearchParams(current)
      if (next === DEFAULT_RANGE) copy.delete('range')          // defaults keep URLs clean
      else copy.set('range', next)
      return copy
    }, { replace: true }), [setParams])                         // replace: no history spam
  return { window, range, setRange }
}
```

- Wrap each URL concern in a hook (`useTimeRange`, `useProjectFilters`); components never
  touch `URLSearchParams` directly.
- Preserve other params when setting one. Omit defaults. Use `replace` for typing/filtering,
  push for navigation.
- Put the resolved value (not the raw string) in query keys: `['traces', projectId, window.key, filters]`.
- Debounce text inputs before they hit the URL or a query key (`useDebouncedValue`).

## Hooks vs context

- Logic reused by two components is a hook; pure computation is a function in `utils/`.
- Context only for app-wide, rarely-changing values (auth status, theme mode, language).
  Split `context.ts` (the object) / `useX.ts` (the hook) / `XProvider.tsx` so fast-refresh
  works and tests can provide fake values.
- Memoise provider values (`useMemo`) and callbacks (`useCallback`).

## Forms

Controlled inputs with local state; validate on submit and show server field errors via
`ApiError.fieldError('email')`. Use `react-hook-form` (+ `zod`) when a form has many fields
or shared validation. Disable the submit button while the mutation is pending.
