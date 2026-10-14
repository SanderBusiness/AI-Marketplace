# Accessibility

- **Real elements.** Actions are `<button>` (MUI `Button`/`IconButton`), navigation is a link
  (`<Link component={RouterLink}>`). Never `onClick` on a `div`.
- **Every control has an accessible name:** visible label for inputs (`<TextField label>`),
  `aria-label` on icon-only buttons, `aria-pressed` on toggles, `aria-busy` on loading blocks.
- **Decorative icons** get `aria-hidden`; informative ones are accompanied by text.
- **Colour is never the only signal** — status chips carry icon + label.
- **Focus:** keep the visible focus ring; move focus into dialogs and back to the trigger on
  close (MUI does this — do not break it); `autoFocus` only where it helps (e.g. a search dialog).
- **Keyboard:** everything reachable and operable with Tab/Enter/Space/Escape; no keyboard traps.
- **Headings** form an outline (one `h1` per page, via `PageHeader`); landmarks (`main`, `nav`).
- **Contrast:** use theme text colours; check secondary/disabled text in both schemes.
- **Motion:** honour `prefers-reduced-motion` (see `styling-and-theming.md`).
- **Errors:** field errors via `error` + `helperText`, announced with `role="alert"` where they
  appear dynamically.
- **Lint it:** oxlint's `jsx-a11y` plugin is on; query by role/label in tests, which doubles as an a11y check.

Use the `web-design-guidelines` skill for a full UI review.
