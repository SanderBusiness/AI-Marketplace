# Next.js for SEO / public sites

Everything else in this skill (small components, one typed API module per feature, theme
tokens, URL as state, accessibility, loading/empty/error states) **still applies**. This file
only adds what is specific to Next.js (App Router).

## Vite SPA or Next.js?

- **Default to Vite + React Router.** Logged-in apps, dashboards, admin tools: no SEO need, no SSR.
- **Choose Next.js only when crawlers or first paint matter**: public marketing/content sites,
  listings, club/portfolio pages, anything that must be indexed or shared with rich previews.
- A fully static site (no server data) can use `output: "export"` and be served by plain nginx.
- Mixed products: public site in Next.js, authenticated app in a separate Vite SPA.

## App Router structure

```
src/
  app/
    sitemap.ts  robots.ts           # outside [locale]
    [locale]/
      layout.tsx  page.tsx  loading.tsx  not-found.tsx  error.tsx
      items/page.tsx  items/[id]/page.tsx
  components/   lib/   i18n/   theme/
```

- `[locale]` routing with `next-intl`: `defineRouting({ locales, defaultLocale, localePrefix: "as-needed" })`
  keeps the default locale unprefixed so existing URLs and search rankings survive.
- Root layout: `generateStaticParams` for locales, `hasLocale(...) || notFound()`, then
  `setRequestLocale(locale)` so pages can render statically.
- `lib/api.ts` stays the single place that talks to the backend (typed, one module per feature
  as it grows). Pages call it; they never inline `fetch`.

## Server vs client components

- Everything is a **Server Component by default**. Add `'use client'` only for state, effects,
  event handlers or browser APIs, and push it to the **smallest leaf** (a button, a chart, a map),
  not the whole page.
- Pass serializable props only. Never pass the MUI theme object or functions across the boundary;
  wrap them in a client provider (see MUI below).
- Browser-only libs (maps, charts): a small client component, loaded with `next/dynamic` if heavy.

## Data fetching, caching, rendering mode

```ts
export async function getItem(id: string): Promise<Item | null> {
  const res = await fetch(`${API_BASE_URL}/Public/Items/${id}`, { next: { revalidate: 60 } });
  if (res.status === 404) return null;            // page calls notFound()
  if (!res.ok) throw new Error(`Failed to fetch item ${id}: ${res.status}`); // error.tsx
  return res.json();
}
```

- Fetch in server components, in parallel (`Promise.all`) when independent.
- Content that changes rarely: static/ISR with `revalidate` (60 s for listings, 3600 s for sitemaps).
- Per-user or request-specific data: do not render it on the server for the public pages; fetch
  it in a client component.

## Metadata, SEO, structured data

```ts
export async function generateMetadata({ params }: PageProps<"/[locale]/items/[id]">): Promise<Metadata> {
  const { locale, id } = await params;
  const item = await getItem(id);
  if (!item) return { title: t("notFound") };
  return {
    title: item.name,                              // layout has title.template "%s | Site"
    description: item.summary,
    alternates: {
      canonical: `/${locale}/items/${id}`,
      languages: Object.fromEntries(routing.locales.map((l) => [l, `/${l}/items/${id}`])),
    },
    openGraph: { title: item.name, description: item.summary, images: [item.imageUrl] },
  };
}
```

- Set `metadataBase: new URL(SITE_URL)` in the root layout, otherwise canonical/hreflang/OG URLs
  stay relative.
- `app/sitemap.ts` lists every public route (dynamic ones fetched from the API, `revalidate` set),
  with per-locale `alternates.languages`. `app/robots.ts` allows `/`, disallows login/admin and
  points to `${SITE_URL}/sitemap.xml`.
- JSON-LD via a small server component. **Escape `<`, `>`, `&`** so content cannot close the tag:

```tsx
export default function JsonLd({ data }: { data: Record<string, unknown> }) {
  const json = JSON.stringify(data).replace(/</g, "\\u003c").replace(/>/g, "\\u003e").replace(/&/g, "\\u0026");
  return <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: json }} />;
}
```

- Semantic HTML: one `<h1>` per page, ordered headings, `<main id="main-content">` plus a skip
  link, `<html lang={locale}>`, descriptive link text.

## Core Web Vitals

- `next/image` with explicit `width`/`height` (or `fill` + sized parent) and `priority` only for the
  LCP image; `next/font` instead of a CSS font import; reserve space for anything that loads late
  (skeletons with fixed heights) to avoid layout shift.
- Third-party scripts via `next/script` with `strategy="afterInteractive"` or `lazyOnload`, never a
  raw `<script>` in the head. Lazy-load heavy client widgets (maps) below the fold.

## MUI with the App Router

Keep the theme and emotion cache inside one client provider, and render it in the layout:

```tsx
"use client";
import { AppRouterCacheProvider } from "@mui/material-nextjs/v16-appRouter";
import { ThemeProvider } from "@mui/material/styles";
import CssBaseline from "@mui/material/CssBaseline";
import theme from "./theme";

export default function ThemeRegistry({ children }: { children: React.ReactNode }) {
  return (
    <AppRouterCacheProvider>
      <ThemeProvider theme={theme}><CssBaseline />{children}</ThemeProvider>
    </AppRouterCacheProvider>
  );
}
```

Pick the `@mui/material-nextjs` entry matching your Next major. Theme tokens rules from
`styling-and-theming.md` apply unchanged.

## Environment variables

- `NEXT_PUBLIC_*` are **inlined at build time** into the browser bundle: changing them at runtime
  does nothing. In Docker pass them as `ARG` then `ENV` in the build stage.
- Therefore they are public by definition: **no secrets in `NEXT_PUBLIC_*`**. Real secrets stay on
  the backend or in server-only variables (no prefix).
- Centralise reads (`lib/siteUrl.ts`) with a sensible fallback instead of scattering `process.env`.

## Analytics and monitoring: only after consent

Non-essential scripts (analytics, browser monitoring) load only after the visitor accepts cookies.
Keep consent in a tiny `lib/cookieConsent.ts` (localStorage + a custom event, guarded with
`typeof window`) and put each tracker in its own client component:

```tsx
"use client";
export default function AnalyticsTracker() {
  const [granted, setGranted] = useState(false);
  useEffect(() => {
    const sync = () => setGranted(getStoredCookieConsent() === "accepted");
    sync();
    window.addEventListener(COOKIE_CONSENT_EVENT, sync);
    return () => window.removeEventListener(COOKIE_CONSENT_EVENT, sync);
  }, []);
  if (!granted || !MEASUREMENT_ID) return null;      // nothing injected, no cookies set
  return <Script src={`https://example.com/tag.js?id=${MEASUREMENT_ID}`} strategy="afterInteractive" />;
}
```

The App Router does not reload on navigation, so send page views from `usePathname` /
`useSearchParams` (wrap trackers using `useSearchParams` in `<Suspense fallback={null}>`).

## Errors and loading

- `not-found.tsx` (friendly page with a link home), `error.tsx` (client component with a retry
  button), `loading.tsx` (skeleton matching the final layout) at the `[locale]` level; add per
  route only when the page needs a different fallback.
- `notFound()` for missing records so crawlers get a real 404, not a 200 with an error message.
- Baseline security headers in `next.config.ts` `headers()` (`X-Content-Type-Options`,
  `X-Frame-Options`, `Referrer-Policy`); add a CSP deliberately, after listing every script source.

## Docker

```dockerfile
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ARG NEXT_PUBLIC_SITE_URL
ARG NEXT_PUBLIC_API_BASE_URL
ENV NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL NEXT_PUBLIC_API_BASE_URL=$NEXT_PUBLIC_API_BASE_URL
RUN npm run build

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production PORT=3000 HOSTNAME=0.0.0.0
COPY --from=builder --chown=node:node /app/public ./public
COPY --from=builder --chown=node:node /app/.next/standalone ./
COPY --from=builder --chown=node:node /app/.next/static ./.next/static
USER node
EXPOSE 3000
HEALTHCHECK CMD wget -qO- http://127.0.0.1:3000/ || exit 1
CMD ["node", "server.js"]
```

Requires `output: "standalone"` in `next.config.ts`. Multi-stage, non-root, no dev dependencies in
the final image. Check that the lockfile installs on Linux (`npm ci`) before relying on it in CI.

## Testing and accessibility

- Vitest + Testing Library for client components (consent banner, trackers, forms); mock
  `next-intl` / `next/navigation` in `vitest.setup.ts`. Unit-test `lib/` code (consent storage,
  formatters, JSON-LD builders, URL helpers) as plain functions.
- Async server components: test the pure data/mapping functions they call; cover the rendered pages
  with Playwright.
- Accessibility basics from `accessibility.md` apply: skip link, one h1, labelled controls,
  visible focus, `lang` set per locale, alt text on every `next/image`.
