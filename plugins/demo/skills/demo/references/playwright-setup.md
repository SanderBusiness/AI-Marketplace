# Playwright setup and demo specs

## Install

- If `@playwright/test` is not in `devDependencies`, add it:
  `npm i -D @playwright/test` then `npx playwright install chromium`.
  Mention this change to the user — it touches `package.json` and the lockfile.
- If Playwright is already present, reuse its version and conventions (folder, fixtures,
  auth setup, page objects). Do not upgrade it.

## Dedicated config

Keep the demo run separate from the project's own e2e config so recording settings and
ports never leak into CI. Create `playwright.demo.config.ts` at the project root:

```ts
import { defineConfig, devices } from '@playwright/test';

const out = process.env.DEMO_OUT ?? '.demo/latest';
const port = Number(process.env.DEMO_PORT ?? 3100);

export default defineConfig({
  testDir: './e2e/demo',
  outputDir: `${out}/test-results`,
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list'], ['json', { outputFile: `${out}/report.json` }]],
  use: {
    baseURL: process.env.BASE_URL ?? `http://localhost:${port}`,
    viewport: { width: 1280, height: 720 },
    video: { mode: 'on', size: { width: 1280, height: 720 } },
    screenshot: 'on',
    trace: 'retain-on-failure',
    launchOptions: { slowMo: Number(process.env.DEMO_SLOWMO ?? 300) },
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: process.env.BASE_URL ? undefined : {
    command: 'npm run dev -- --port ' + port, // adapt to the stack, see preflight.md
    url: `http://localhost:${port}`,
    reuseExistingServer: true,
    timeout: 120_000,
  },
});
```

`slowMo` makes the video watchable; set `DEMO_SLOWMO=0` for a fast verification run. If
the project uses a `.js`/`.mjs` config style, match it.

## One spec per acceptance criterion

Put specs in `e2e/demo/<slug>.spec.ts`. Each test title starts with its AC number so the
results can be mapped back: `AC1 — <short wording>`. A test that covers two ACs is split
into two tests; an AC that needs several scenarios gets `AC3a`, `AC3b`.

Use a `step` helper so every meaningful moment becomes a named screenshot attached to the
test result (these become the screenshot strip under each video):

```ts
import { test, expect, type Page, type TestInfo } from '@playwright/test';

async function shot(page: Page, info: TestInfo, label: string) {
  await info.attach(label, { body: await page.screenshot({ fullPage: false }), contentType: 'image/png' });
}

test.describe('ABC-123 Filter products by category', () => {
  test('AC1 — user can pick a category from the filter bar', async ({ page }, info) => {
    await page.goto('/products');
    await shot(page, info, 'Product list without filter');

    await page.getByRole('button', { name: 'Category' }).click();
    await page.getByRole('option', { name: 'Shoes' }).click();
    await shot(page, info, 'Shoes selected');

    await expect(page.getByTestId('product-card')).not.toHaveCount(0);
    await expect(page.getByTestId('product-card').first()).toContainText('Shoe');
  });
});
```

Rules:
- **Every AC test must end in assertions that prove the AC**, not just clicks. The
  assertion is what makes it "proven"; the video only shows it.
- Prefer role/label/test-id locators; avoid brittle CSS and fixed `waitForTimeout`s
  (a short pause before a final screenshot for animations is fine).
- Use a few meaningful `shot()` calls per test (3–6), labelled as a viewer would describe
  the screen.
- Optionally add a `Walkthrough` test (no AC prefix) that runs the full happy path in one
  go; its video becomes the headline demo.
- Stub or seed external data only if the app can't run without it, and say so in the
  report.

## Run

```bash
DEMO_OUT=.demo/<slug>/after npx playwright test -c playwright.demo.config.ts
```

If a test fails, look at the error and trace. Fix the **test** if it is wrong (bad
locator, timing); if the **feature** is wrong, do not weaken the assertion — the AC is
reported as failing (see `acceptance-criteria.md`). Only change application code if the
user asked you to finish the feature as well.

Then collect results:

```bash
node <skill-dir>/scripts/collect-results.mjs .demo/<slug>/after
```

This writes `.demo/<slug>/after/manifest.json` and copies videos (MP4 if `ffmpeg` is
available, otherwise WebM) and screenshots into `.demo/<slug>/after/media/`.
