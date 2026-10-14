# Components

- **One component per file**, named like the file, `export default` or a single named export.
- **One responsibility, ~150 lines max.** Split before it grows, not after.
- **Logic goes in hooks (`useX`) and pure functions (`utils/`)**; the component renders.
- **Props over global state.** Context is for truly app-wide things (auth, theme).
- **Reusable where it makes sense:** generic, prop-driven pieces (page header, empty state,
  status chip, card) live in `components/common` and take data and callbacks via props. Feature
  components stay next to their page.
- **Not prematurely abstracted (KISS):** copy once, extract on the second real use. Do not add
  props "just in case"; a component with a dozen booleans is two components.
- Prefer composition (`children`, slots) over flags.
- Keep props typed and small; pass ids/values rather than whole objects when that is all it needs.

## Splitting a too-big component

Before: one 300-line `ProjectsPage` that fetches, filters, formats and renders.

```tsx
// pages/ProjectsPage.tsx — composes only
export default function ProjectsPage() {
  const { filters, setSearch } = useProjectFilters()   // URL state, see state-and-urls.md
  const projects = useProjects(filters)                // api/projects.ts
  return (
    <>
      <PageHeader title="Projects" actions={<NewProjectButton />} />
      <SearchField value={filters.search} onChange={setSearch} />
      <QueryBoundary query={projects} empty={<NoProjects />}>
        {(items) => <ProjectGrid projects={items} />}
      </QueryBoundary>
    </>
  )
}
```

```
pages/ProjectsPage.tsx           # composition
pages/projects/useProjectFilters.ts  # hook: URL <-> filters
pages/projects/ProjectGrid.tsx       # layout of cards (cards on phones, table from md)
pages/projects/ProjectCard.tsx       # one project
utils/format.ts                      # formatDuration(), formatCount() — pure, unit-tested
```

## States: every data view handles all three

```tsx
export function EmptyState({ title, children, action, icon }: Props) {
  return (
    <Stack spacing={1} sx={{ alignItems: 'center', py: 6, textAlign: 'center', color: 'text.secondary' }}>
      {icon}
      <Typography variant="subtitle1" color="text.primary">{title}</Typography>
      {children && <Typography variant="body2">{children}</Typography>}
      {action}
    </Stack>
  )
}
```

- **Loading:** a skeleton shaped like the content (`aria-busy`), not a lone spinner.
- **Empty:** say what would fill it and offer the action ("No projects yet. Create one").
- **Error:** plain-language message from `ApiError` plus a **Try again** button (`refetch`).
  Network errors say so ("Check your connection").
- Keep previous data on screen while the next window loads (`placeholderData: keepPreviousData`).
- Numbers use `tabular-nums`; ids and stack traces use the monospace font.
