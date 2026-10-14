# Mobile and PWA

See the `mobile-native` skill for the full rationale; this is the baseline to start from.

## Native-feel baseline

`index.html`:

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, interactive-widget=resizes-content" />
<meta name="theme-color" content="#FFFFFF" media="(prefers-color-scheme: light)" />
<meta name="theme-color" content="#0F0E0D" media="(prefers-color-scheme: dark)" />
<meta name="color-scheme" content="light dark" />
<meta name="mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
```

Global CSS (via `CssBaseline` overrides):

- Full-height layouts use `100dvh`, never `100vh`.
- Respect safe areas: `padding: env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)` on fixed bars.
- **Inputs are >= 16 px** (otherwise iOS zooms the page on focus).
- `-webkit-tap-highlight-color: transparent`; `touch-action: manipulation` on buttons/links.
- Hover only under `(hover: hover) and (pointer: fine)`.
- Test on a real phone, not only devtools.

## PWA with vite-plugin-pwa

```ts
VitePWA({
  registerType: 'autoUpdate',          // new SW activates at once; app reloads itself
  strategies: 'generateSW',
  includeAssets: ['favicon.svg', 'apple-touch-icon.png'],
  manifest: { id: '/', name: 'App', short_name: 'App', display: 'standalone', start_url: '/', scope: '/',
    theme_color: '#C2410C', background_color: '#FAFAF9',
    icons: [ /* 192, 512 'any', 512 'maskable' */ ] },
  workbox: {
    globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2,webmanifest}'],   // app shell only
    navigateFallback: 'index.html',
    navigateFallbackDenylist: [/^\/api\//],
    skipWaiting: true, clientsClaim: true, cleanupOutdatedCaches: true,
    runtimeCaching: [],                // never cache API data
  },
})
```

- **Precache the app shell only. Never cache API responses** in the service worker; the data
  layer (TanStack Query with `networkMode: 'online'`) decides freshness.
- Keep `/api` out of the navigation fallback.
- Show an update snackbar/offline banner (`useOnline`) rather than failing silently.
- Ship only the font subsets you need (e.g. latin) and ignore the rest in `globIgnores`.
- Split heavy vendor chunks (`mui`, `vendor`) in `build.rolldownOptions.output.codeSplitting`.
- Lazy-load route pages (`React.lazy`) so the first load stays small.
