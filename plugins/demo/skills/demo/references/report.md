# Building and publishing the demo page

## Inputs

- `.demo/<slug>/after/manifest.json` — tests, statuses, videos, screenshots
  (from `scripts/collect-results.mjs`).
- `.demo/<slug>/before/*.png` and `.demo/<slug>/after-shots/*.png` — the comparison.
- Title, summary, ACs, base/head SHAs from preflight.

## Assemble

Copy `assets/report-template.html` to `.demo/<slug>/index.html` and fill it in. Keep the
four sections in order and don't add others except a short "How this was tested" footer.

1. **Title** — `<ticket> — <feature name>`; subtitle = one-line summary + the AC summary
   line (see `acceptance-criteria.md`); meta line = branch, base SHA → head SHA, date.
2. **Demo** — the `Walkthrough` video first if it exists, then one card per AC test:
   video (`<video controls muted playsinline preload="metadata">`) and its screenshots as a
   captioned strip. Use the screenshot labels from the manifest as captions.
3. **Before / After** — one row per captured state: before left, after right (stacked on
   narrow screens), captioned with the state name and any note ("did not exist before").
4. **Acceptance criteria** — one row per AC: number, original wording, status badge,
   evidence (link/anchor to the demo card, test file:line, or the explanation/error).

Media paths are relative (`media/…`, `before/…`, `after-shots/…`) so the same folder works
opened locally and published.

## Size

- Keep individual videos small: MP4 at CRF 28, 1280×720, is typically 0.5–3 MB per
  test. Re-encode with a higher CRF or lower resolution if one exceeds ~10 MB.
- Screenshots: PNG is fine; convert large full-page ones to JPEG/WebP (quality 80) if the
  total gets over ~20 MB.

## Publish

- If the environment can publish HTML pages/artifacts, publish `index.html` with the
  media files as supporting files (relative paths as above), then give the user the link.
  Follow that environment's page conventions (title, theme tokens, dark mode).
- Otherwise leave `.demo/<slug>/index.html` in place and tell the user to open it; offer
  to zip the folder for sharing.

## Final message to the user

Short: link/path, the AC summary line, anything **Failing** or **Not implemented**, and
what was changed in their repo (Playwright added? new spec files? `.gitignore`).
