# Realistic demo videos

The recordings must look like a person is operating the app: a visible cursor that glides,
scrolling that eases, readable subtitles that say what is happening, and a clear moment for
every click. Playwright on its own records none of that — the video has no cursor, and
`locator.click()`, `fill()`, `goto()` and Playwright's automatic scroll-into-view all jump
instantly. `assets/demo-human.ts` fixes this; copy it to `e2e-demo/demo-human.ts`.

## Hard rules for the AC specs

- **Every interaction goes through `Demo`**: `demo.click`, `demo.type`, `demo.press`,
  `demo.scrollTo`, `demo.scrollBy`. Never call `locator.click()`, `locator.fill()`,
  `locator.check()`, `selectOption()`, `scrollIntoViewIfNeeded()` or `page.mouse.*`
  directly in a demo spec. Locators are still fine for *reading* state and in `expect`.
- **One `demo.open()` per test, at the start.** After that, navigate the way a visitor
  would: click the menu item, the link, the button. A second `goto` is a teleport.
- **A subtitle for every step**, written for the viewer in the project's language, in the
  present tense ("We kiezen club Kalfort Sportif", "The list now only shows…"). Pass it as
  the `text` argument of the action, or call `demo.caption()` for an observation after an
  action ("De lijst toont nu enkel wedstrijden van Kalfort Sportif"). Keep them short (one
  line, under ~80 characters).
- **Show the proof on screen** before asserting it in code: after a filter, caption what
  changed and scroll a little through the result so the viewer sees it. Assertions stay in
  the test and run while the subtitle is up.
- **No invisible waiting.** If data takes a moment, caption it ("De kalender laadt…")
  rather than showing a frozen frame without explanation.
- Things outside the page — downloads, a print tab, a feed URL — can't be seen in the
  video. Caption what happens ("Het bestand kbkb-kalender-…csv wordt gedownload") and
  attach a screenshot of the popup/tab instead.
- Use `demo.withoutCaption(() => shot(page, info, '…'))` for step screenshots so the
  subtitle doesn't duplicate the report's own caption. The cursor stays visible.

## Settings

- `slowMo: 0` in the demo config: pacing comes from `Demo`. `slowMo` would slow every
  micro-step and make the video crawl.
- Keep it brisk. A viewer wants to see the change, not wait for it: typing runs at ~45 ms
  per key, a cursor glide takes at most 0.7 s, and captions stay up only as long as it takes
  to read them. Don't add `demo.pause()` or long captions between every step; one caption
  per meaningful moment is enough.
- Never drive the video with a Playwright call per animation step (a `mouse.move` +
  `waitForTimeout` per frame, a `keyboard.type` per character). Every call is a round trip,
  and on a recording they add up to seconds per action while the cursor still looks like it
  jumps. `Demo` animates the cursor inside the page in one call and types with one
  `keyboard.type(value, { delay })`.
- Viewport and video size equal (1280×720) so the overlay is not scaled.
- The overlay survives navigations (state in `sessionStorage`) and re-attaches itself if a
  framework re-renders `<body>`.

## Example

```ts
test('AC1 — clubfilter toont enkel wedstrijden van die club', async ({ page }, info) => {
  const demo = await Demo.start(page);
  await demo.open('/kalender', 'We openen de kalender van seizoen 2026-2027');
  await demo.click(page.getByRole('combobox', { name: /^Club/ }), 'We openen de nieuwe clubfilter');
  await demo.click(page.getByRole('option', { name: 'Kalfort Sportif', exact: true }), 'We kiezen Kalfort Sportif');
  await demo.caption('De lijst toont nu enkel wedstrijden van Kalfort Sportif');
  await demo.scrollBy(400);
  await demo.withoutCaption(() => shot(page, info, 'Gefilterd op Kalfort Sportif'));
  // assertions on the filtered rows ...
});
```

The before/after `capture.spec.ts` is not a video and doesn't use `Demo`.

## Check the recording before publishing

Look at a few frames of at least one video: is the cursor visible, does a subtitle show,
is nothing covered? No `ffmpeg` needed — open a small local HTML page with a `<video>`
pointing at the `.webm` in Playwright (via `file://`, not `setContent`), set
`currentTime` to a few moments, wait for `seeked`, and screenshot. Keep the helper files
inside `.demo/` so they are removed with it.
