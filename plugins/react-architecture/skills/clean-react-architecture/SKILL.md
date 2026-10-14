---
name: clean-react-architecture
description: Reference architecture for React frontends (React + TypeScript + Vite + MUI + TanStack Query + React Router, PWA, Vitest/Testing Library, oxlint) — small single-responsibility components, logic in hooks and pure functions, one typed API module per backend controller/feature, URL as state, theme tokens, accessibility, mobile-first and PWA rules. Load this when scaffolding a React frontend, deciding where a component/hook/API module belongs, or writing or reviewing React components, hooks, API modules, theming, or frontend tests.
---

Use this skill whenever you're structuring a React frontend, deciding where a component,
hook or API call belongs, or writing/reviewing UI code. Default to **small, focused files**
and to **boring, typed, testable code** (SOLID + KISS).

Principles:

- **Mobile-first.** Design the phone layout first, enhance from `sm`/`md` up.
- **Components render, hooks and pure functions think.** One component per file, one
  responsibility, ~150 lines max — split before it grows. Props over global state.
- **Data only through the API layer.** One `src/api/<feature>.ts` per backend
  controller/feature (typed request functions + query hooks + query keys), a transport-only
  `client.ts`. No `fetch` in components.
- **The URL is state** for filters, tabs and time ranges, so links are shareable.
- **Theme tokens only** — never hard-coded colours; light, dark and system modes.
- **Accessible by default** — real buttons/links, labels, focus, keyboard.
- **Every screen has loading, empty and error states.**
- **KISS over abstraction.** Reuse where it makes sense; do not generalise before the second use.

Read only the reference file(s) relevant to the task at hand:

- **`references/project-layout.md`** — folder structure and where each kind of file lives.
  Load when scaffolding or deciding where something belongs.
- **`references/components.md`** — small/reusable component rules, an example of splitting
  a too-big component, loading/empty/error states. Load when writing or reviewing a component.
- **`references/data-fetching.md`** — per-feature API modules, the client, `ApiError`
  (RFC 7807), token refresh, query hooks and keys. Load when touching anything that calls the backend.
- **`references/state-and-urls.md`** — URL state, hooks vs context, forms. Load for filters,
  time ranges, shared state.
- **`references/styling-and-theming.md`** — theme tokens, status colours, motion rules,
  charts. Load when styling or adding charts.
- **`references/mobile-and-pwa.md`** — mobile-native baseline and the service-worker rules.
  Load for layout on phones, `index.html`, or PWA config.
- **`references/accessibility.md`** — semantics, labels, focus, keyboard. Load when building interactive UI.
- **`references/testing.md`** — Vitest + Testing Library conventions. Load when writing tests.
- **`references/nextjs.md`** — Next.js (App Router) for SEO/public sites: when to choose it over Vite,
  server vs client components, metadata, sitemap, JSON-LD, consent-gated scripts, Docker. Load for SEO/public sites built with Next.js.
- **`references/tooling.md`** — versions, scripts, tsconfig, oxlint, Vite config. Load when
  scaffolding or checking dependencies.

Complementary skills (do not duplicate their content): `dataviz` (charts), `emil-design-eng`
and `animate` (polish and motion), `mobile-native` (native feel), `web-design-guidelines`
(UI review), `break-ui` (worst-case data).
