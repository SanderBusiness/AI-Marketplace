# Styling and theming

## Theme tokens only

- Colours, radii, fonts and transitions come from the MUI theme (`sx={{ color: 'text.secondary' }}`,
  `bgcolor: 'background.paper'`). **Never hard-code a colour in a component.**
- Support **light, dark and system**: `createTheme({ cssVariables: { colorSchemeSelector: 'data' }, colorSchemes: { light, dark } })`
  and a mode switch built on `useColorScheme()`.
- Non-MUI colour sets (chart palette, status colours) live in `theme/palette.ts` as per-mode
  objects; components read them through a hook (`useChartColors()`), not constants.
- Add `<meta name="color-scheme" content="light dark">` and per-scheme `theme-color` metas.
- Text is English by default; add `i18next` (Vite) or `next-intl` (Next) from the start if more
  than one language is likely, and keep all strings in locale files.
- Numbers: `tabular-nums` (a shared `numeric` sx object). Ids and code: a monospace font.

## Status is never colour alone

```tsx
const icons = { ok: CheckCircleOutline, warning: WarningAmber, error: ErrorOutline, info: InfoOutlined }
export default function StatusChip({ status, label }: { status: StatusKind; label: string }) {
  const Icon = icons[status]
  return (<Box component="span" sx={{ display: 'inline-flex', gap: 0.5 /* colours from theme */ }}>
    <Icon aria-hidden />{label}</Box>)
}
```

Always icon + label. Error red is reserved for errors; brand colour is not a status colour.

## Motion

- **<= 200 ms, ease-out** (`cubic-bezier(0.23, 1, 0.32, 1)`); define `EASE_OUT`/`TRANSITION`
  once in the theme and map MUI `transitions.duration` to it.
- **No animation for frequent actions** (typing, switching tabs, table sorting). Press feedback
  only: `&:active { transform: scale(0.97) }`.
- Respect `prefers-reduced-motion: reduce` (disable transforms and large movement).
- Hover styles only under `@media (hover: hover) and (pointer: fine)` — otherwise touch
  devices get stuck hover states.
- Disable MUI ripple (`MuiButtonBase.defaultProps.disableRipple`) if you use scale press feedback.

## Layout

- Mobile first: base styles are the phone layout; add `sm`/`md` breakpoints upward. Wide tables
  scroll in a box or become cards on phones.
- Touch targets >= 44 px under `@media (pointer: coarse)`.

## Charts

All chart code lives in one `src/charts/` module wrapping one library; pages never import it.
Rules (see the `dataviz` skill for depth):

- Categorical colours from `seriesColor(index, mode)` in **fixed order, never cycled**.
- **One y-axis.** No dual axes.
- **Every chart has a table view** (a toggle in `ChartCard`, `aria-pressed`).
- **No chart animation.**
- A `ChartCard` owns title, loading skeleton, error + retry, and the table toggle.
