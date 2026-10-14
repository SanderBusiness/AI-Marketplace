# Tooling and versioning

- **Always use the latest stable versions** of Node, React, TypeScript, Vite, MUI, TanStack
  Query, React Router, Vitest, oxlint — check the registry (`npm view <pkg> version`) when
  scaffolding. Use `^` ranges.
- **Commit `package-lock.json`.** A gitignored lockfile makes CI resolve different versions
  than your machine and produces lint/build failures on code you did not touch.
- Prefer **oxlint** over ESLint (fast, near zero config). One linter, not both.
- Prefer **Vite** (+ `@vitejs/plugin-react`) for apps; Next.js only when SSR/SEO is needed.
- Prefer **TanStack Query** over axios + hand-written `useHttp` hooks; plain `fetch` in `client.ts`
  is enough (no axios).

## Scripts

```json
{
  "dev": "vite",
  "build": "tsc -b && vite build",
  "lint": "oxlint",
  "preview": "vite preview",
  "test": "vitest run",
  "test:watch": "vitest"
}
```

`npm run lint`, `npm test` and `npm run build` must pass. The build type-checks first (`tsc -b`).

## tsconfig.app.json (essentials)

```json
{
  "target": "es2023", "lib": ["ES2023", "DOM", "DOM.Iterable"],
  "module": "esnext", "moduleResolution": "bundler", "jsx": "react-jsx",
  "types": ["vite/client", "vite-plugin-pwa/react", "vitest/globals", "@testing-library/jest-dom"],
  "verbatimModuleSyntax": true, "erasableSyntaxOnly": true, "noEmit": true,
  "strict": true, "noUnusedLocals": true, "noUnusedParameters": true,
  "noFallthroughCasesInSwitch": true, "noUncheckedSideEffectImports": true
}
```

Plus `tsconfig.node.json` for `vite.config.ts`/`vitest.config.ts`, and a root `tsconfig.json`
with project references. No `any` (lint-enforced); no `enum` (use string unions).

## .oxlintrc.json

```json
{
  "plugins": ["react", "typescript", "oxc", "jsx-a11y", "vitest"],
  "categories": { "correctness": "error", "suspicious": "warn" },
  "rules": {
    "react/rules-of-hooks": "error",
    "react/exhaustive-deps": "warn",
    "react/only-export-components": ["warn", { "allowConstantExport": true }],
    "typescript/no-explicit-any": "error",
    "react/react-in-jsx-scope": "off"
  },
  "ignorePatterns": ["dist", "dev-dist", "coverage", "node_modules"]
}
```

Suppress a rule only on the line, with a one-line reason
(`// oxlint-disable-next-line <rule> -- why`). Never blanket-disable.

## Config and secrets

Read `import.meta.env` once in `config.ts`. Only non-secret values (`VITE_API_URL`) belong in
the bundle; secrets never reach the frontend repo. Use a same-origin `/api` proxy in
`vite.config.ts` for development.
