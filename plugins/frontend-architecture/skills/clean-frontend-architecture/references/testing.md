# Testing

Vitest + React Testing Library + `@testing-library/user-event` + jsdom. Globals on
(`vitest/globals`), tests sit next to the code (`client.test.ts`).

- **Test behaviour, not implementation.** Query by role, label and text
  (`getByRole('button', { name: /save/i })`), never by class names or internals.
- **Pure functions are unit-tested** (formatters, range parsing, `errorMessage`, mappers).
- **Stub `fetch`, not your own modules**: `vi.stubGlobal('fetch', vi.fn(async () => jsonResponse(...)))`.
  This exercises the real client, query hooks and error mapping.
- Cover the contract of the client: bearer header, `credentials: 'include'`, refresh once on 401
  and retry, **one shared refresh for concurrent 401s**, `ApiError` from problem details, network error -> status 0.
- Test the three states of a view: loading, empty, error (with retry).
- Test the a11y-relevant behaviour users rely on (keyboard, labels, disabled while pending).

## Shared helpers (`src/test/helpers.tsx`)

```tsx
export function renderWithProviders(ui: ReactNode, route = '/') {
  return render(
    <QueryClientProvider client={createQueryClient()}>   {/* fresh client per test */}
      <AppThemeProvider>
        <MemoryRouter initialEntries={[route]}>{ui}</MemoryRouter>
      </AppThemeProvider>
    </QueryClientProvider>,
  )
}
export const jsonResponse = (body: unknown, status = 200) =>
  new Response(body === undefined ? null : JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })
```

`setupTests.ts`: import `@testing-library/jest-dom/vitest`, polyfill `matchMedia` (jsdom lacks it;
MUI needs it), and in `afterEach` call `cleanup()`, `vi.unstubAllGlobals()`, `vi.restoreAllMocks()`
and reset the in-memory session.

Config: separate `vitest.config.ts` (no PWA plugin; alias the PWA register module to a mock;
`env: { VITE_API_URL: 'http://api.test' }`).

For end-to-end flows add Playwright (`e2e/`), kept out of the unit-test run. Run `npm test`,
`npm run lint` and `npm run build` before declaring work done.
