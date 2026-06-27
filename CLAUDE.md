# Mad Minutes — CLAUDE.md

## What this is

A single-file, no-build SPA for the classic "Mad Minutes" timed math worksheet.
Students complete 25 arithmetic problems per page, with an optional countdown timer
and printable output. All code lives in `index.html`.

## Architecture

**One file, no build step.** Everything — HTML, CSS, JavaScript, JSX — lives in
`index.html`. Do not introduce a bundler, `package.json`, or separate source files
unless the user explicitly requests it.

**Runtime dependencies (CDN only):**

| Library | Version | Purpose |
| --- | --- | --- |
| Bootstrap | 5.3.2 | Layout, components, utilities |
| Font Awesome | 6.5.0 | Icons |
| React | 18 (UMD production) | UI rendering |
| ReactDOM | 18 (UMD production) | DOM mounting |
| Babel Standalone | latest | In-browser JSX transpilation |

All scripts load via CDN before the `<script type="text/babel">` block. Do not swap
to ESM imports or local files.

## Code structure

The entire JS lives in a single `<script type="text/babel">` block. Sections are
separated by banner comments:

```text
/* ── Section Name ── */   ← minor sections (CSS and JS)
{/* ════ Section ════ */}  ← major JSX sections inside render
```

Keep this pattern. Do not invent new comment styles.

**One top-level React component:** `App`. All state lives there. Do not split into
multiple components unless the file grows unmanageable (>1500 lines).

## Naming conventions

### CSS classes

| Prefix / Name | Scope |
| --- | --- |
| `ws-*` | Worksheet header sub-elements |
| `p-*` | Problem cell sub-elements (`p-number`, `p-operator-row`, `p-divider`) |
| `cell-*` | Problem cell state modifiers (`cell-correct`, `cell-incorrect`) |
| `modal-op-btn` | Settings modal operation buttons |
| `action-bar` | Sticky top bar during play |
| `timer-*` | Timer display elements |
| `page-sep` | Screen-only separator between worksheet pages |
| `idle-screen` | Full-viewport centered splash |
| `no-print` | Utility — hidden in `@media print` |
| `print-page-break` | Forces a page break before the element |
| `section-label` | Small caps label above form groups in modals |

Avoid Bootstrap's `p-*` spacing utilities on problem cell children — the prefix
conflicts. Use explicit padding values instead.

### JavaScript

- `UPPER_SNAKE_CASE` for module-level constants: `DEFAULTS`, `OP_META`, `LS_KEY`
- `camelCase` for functions and variables
- Prefix action handlers with `do`: `doGenerate`, `doCheck`
- Prefix event handlers with `on`: `onKeyDown`, `onAnswerChange`
- Curried config setters return functions: `setCfgField(key)`, `setCfgInt(key)`

### State

`phase` is the primary state machine:

```text
'idle'    → 'active'   (doGenerate)
'active'  → 'checked'  (doCheck or timer expiry)
'checked' → 'active'   (doGenerate again via Settings modal)
```

Config lives in the `cfg` object. Seed is part of `cfg`. Never split seed into
separate top-level state.

## CSS conventions

- Embed all custom styles in the `<style>` block in `<head>`, above Bootstrap.
- Use Bootstrap utility classes for spacing, flex, color, and typography wherever
  possible. Write custom CSS only for structural rules Bootstrap cannot express.
- Transitions: `0.25s` for background/border-color changes on interactive elements.
- Bootstrap semantic color tokens map to:
  - `success` → green (#198754)
  - `danger` → red (#dc3545)
  - `primary` → blue (#0d6efd)
  - `warning` → yellow/amber
- Dynamic color classes use template literals: `` `btn-${opMeta.color}` ``,
  `` `bg-${opMeta.color}` ``. Keep all four operation colors (success, danger,
  primary, warning) so Tailwind/PurgeCSS concerns do not apply here (Bootstrap is
  CDN-loaded).

## Print layout

- `@media print` block at the bottom of `<style>`. Keep all print rules there.
- `@page { margin: 0.5in; size: portrait; }` — do not change this.
- `.no-print` hides the action bar, modals, and page separators.
- `.ws-name-date` is `display: none` on screen and `display: flex` on print.
- `.ws-seed-footer` is `display: none` on screen and `display: block` on print.
- Problem cells use `break-inside: avoid` to prevent splits across pages.
- Print cells must have an explicit `min-height` (currently `110px`) smaller than
  the screen value (`132px`) to fit more on a printed page.

## Dark mode

The app currently uses a hardcoded light background (`body { background: #f0f4f8 }`).
Per the project CLAUDE.md, new or changed UI should respect `prefers-color-scheme`.
When adding new UI sections, use CSS custom properties or media queries rather than
hardcoding `#f0f4f8` or `white`. A full dark-mode pass is pending.

## Problem generation

- **PRNG:** `mulberry32(seed)` — seeded, deterministic. Same seed + same config always
  produces the same problem set.
- **`genProblem(rng, op, cfg)`** handles all four operations. Division generates
  `divisor × quotient` first to guarantee whole-number answers.
- Addition supports an optional sum cap (`useSumCap` / `sumCap`) that constrains
  `a + b ≤ cap`.
- Subtraction supports `noNeg` to ensure `a ≥ b`.
- Both addition and subtraction support `noCarry` (boolean). When true, the
  generator retries (up to 60 attempts) until it finds a pair where no digit column
  requires a carry (addition) or borrow (subtraction): e.g. 13+16 ✓, 17+17 ✗;
  28-12 ✓, 28-19 ✗. The check is in `hasCarryOrBorrow(a, b, op)`. On the rare
  case that no valid pair is found in 60 tries, the constraint is silently dropped
  for that one problem rather than looping forever. `noCarry` for subtraction
  implies `noNeg` mathematically (column-wise a≥b means overall a≥b), but both
  flags may be active independently.
- 25 problems per page; `cfg.pages` (1–6) controls how many pages are generated.

## URL + persistence

- `cfg` is serialized to `window.location.hash` via `URLSearchParams` on every
  change (the `encodeHash` / `parseHash` helpers). This makes any sheet shareable
  by URL.
- Last-used settings (excluding seed) persist in `localStorage` under the key
  `madMinutesSettings`. The seed is always randomized on fresh load.

## Bootstrap modal usage

```js
new bootstrap.Modal(el, { backdrop: 'static', keyboard: false })  // settings modal
new bootstrap.Modal(el, { backdrop: true,     keyboard: true  })  // help modal
```

Show/hide via the `bsModal.current` / `bsHelpModal.current` refs. Do not use
Bootstrap's data-attribute API.

## Keyboard shortcuts

| Key | Context | Action |
| --- | --- | --- |
| `?` | Always | Open help modal |
| `Esc` | Settings modal open | Randomize seed |
| `Enter` | Settings modal, not in input | Start Timer |
| `Esc` | Active play, no modal | Open Settings |
| `C` / `c` | Active play | Check Answers |
| `Enter` | Answer input | Move to next input; auto-check when all filled |

New shortcuts must be added to the global `onGlobalKey` handler and documented in
the help modal table.

## Accessibility

- Answer inputs use `aria-label="Problem N"`.
- Operation toggle uses `role="group"` with `aria-label`.
- Modal close buttons have `aria-label="Close"`.
- Maintain these patterns on any new interactive element.

## What not to add

- No TypeScript, no JSDoc, no `package.json`.
- No separate component files or module imports.
- No test harness (there is no test runner in a single HTML file).
- No build tooling unless the user explicitly requests a refactor to a proper project
  structure.
