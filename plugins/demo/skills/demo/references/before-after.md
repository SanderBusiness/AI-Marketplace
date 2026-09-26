# Before / after screenshots

The comparison shows the same screens, in the same state and viewport, on the base ref
and on the current change.

## 1. Define the screens once

Create `e2e/demo/capture.spec.ts` with a list of states relevant to the change — the
pages/components the diff touches. Each state is a URL plus optional setup actions:

```ts
import { test } from '@playwright/test';

const states: { name: string; path: string; setup?: (page: import('@playwright/test').Page) => Promise<void> }[] = [
  { name: 'product-list', path: '/products' },
  { name: 'filter-open', path: '/products', setup: async (p) => { await p.getByRole('button', { name: 'Category' }).click(); } },
];

test.describe('capture', () => {
  test.skip(!process.env.DEMO_SHOTS, 'only runs when capturing before/after');
  test.use({ video: 'off' });

  for (const s of states) {
    test(`capture ${s.name}`, async ({ page }) => {
      await page.goto(s.path);
      await page.waitForLoadState('networkidle');
      try { await s.setup?.(page); } catch { /* control may not exist on base */ }
      await page.screenshot({ path: `${process.env.DEMO_SHOTS}/${s.name}.png`, fullPage: true });
    });
  }
});
```

Setup actions that depend on the new feature will fail on the base — the `try` keeps the
screenshot of whatever the base shows instead. That is the honest "before".

## 2. Run the base in a worktree

```bash
BASE=$(git merge-base HEAD origin/main)
git worktree add .demo/<slug>/base-src "$BASE"
cp .env* .demo/<slug>/base-src/ 2>/dev/null   # untracked env files aren't in the worktree
cd .demo/<slug>/base-src && npm ci
npm run dev -- --port 3101 &                    # port override: see preflight.md
```

Wait until the port responds, then from the **project root** (the capture spec must
come from the current code, since the base doesn't have it):

```bash
BASE_URL=http://localhost:3101 DEMO_SHOTS=.demo/<slug>/before \
  npx playwright test -c playwright.demo.config.ts capture
```

## 3. Capture the after

```bash
DEMO_SHOTS=.demo/<slug>/after-shots npx playwright test -c playwright.demo.config.ts capture
```

(The config's `webServer` starts the current app on port 3100.)

## 4. Clean up

Stop the base dev server and remove the worktree:
`git worktree remove --force .demo/<slug>/base-src`.

## Edge cases

- **New page that didn't exist before**: the base shows a 404 — keep it, and caption it
  "did not exist before".
- **Base doesn't build** (e.g. migrations, changed env): note it in the report and show
  "before" as unavailable rather than faking it.
- **Dynamic content** (dates, random data, animations): freeze it with
  `page.clock.setFixedTime(...)` / `page.emulateMedia({ reducedMotion: 'reduce' })` on both
  runs so differences come from the change, not from noise.
- **Backend differences**: both runs use the same backend/env unless the change includes
  backend work; say which in the report.
