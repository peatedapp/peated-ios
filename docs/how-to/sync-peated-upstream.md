# Sync Peated Upstream

This guide identifies the backend, API, and web design sources used to keep the iOS app aligned with Peated.

## Where to look

The repositories normally live beside one another:

```text
<workspace>/peated-ios
<workspace>/peated
```

From the `peated-ios` repository root, the expected backend/web checkout is therefore `../peated`.

- The production API specification is `https://api.peated.com/spec.json`. Use it to generate `PeatedAPI`; do not generate the client from TypeScript types or a locally running server.
- Backend behavior lives in `../peated/apps/server/src/orpc/routes/`, with response serialization in `../peated/apps/server/src/serializers/`.
- The shared design guide lives in `../peated/DESIGN.md`.
- Exact web colors and measurements live in `../peated/apps/web/src/styles/tokens.stylex.ts`.
- Examples of shared components and their states live in the `*.stories.tsx` and `*.stylex.tsx` files under `../peated/apps/web/src/components/`.
- Complete web pages live under `../peated/apps/web/src/app/`. Use them to understand content order and behavior at different sizes, while following iOS interaction and navigation conventions.

The production OpenAPI document defines API requests and responses. The backend code explains behavior the specification cannot show. `DESIGN.md`, the web styles, component examples, and complete pages define the redesign. Use screenshots to review the result, not as the only design reference.

## Refresh the backend checkout

First inspect the sibling checkout so active work is not overwritten or accidentally merged:

```bash
git -C ../peated status --short --branch
git -C ../peated remote -v
```

If it is a clean checkout of `main`, update it with a fast-forward-only pull:

```bash
git -C ../peated pull --ff-only origin main
```

If it is on a feature branch, do not merge `main` into that branch merely to inspect upstream. Fetch the current remote and read `origin/main`, or use a separate clean worktree:

```bash
git -C ../peated fetch origin main
git -C ../peated show origin/main:DESIGN.md
git -C ../peated show origin/main:apps/web/src/styles/tokens.stylex.ts
```

In managed worktrees, `../peated` may not exist. The Git common directory points back to the main `peated-ios` checkout, so the backend beside it can be found without a machine-specific path:

```bash
git -C "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")/peated" status --short --branch
```

Use that resolved path anywhere this guide says `../peated`.

Record the backend commit used for a migration in the pull request description:

```bash
git -C ../peated log -1 --format='%H %cI %s' origin/main
```

## Refresh the API client

Use the repository script from the `peated-ios` root:

```bash
./Scripts/update-api.sh
```

It downloads the production specification, applies the fixes required by the generator, rebuilds `PeatedAPI/Sources/PeatedAPI/Generated/`, and compiles the package. Never hand-edit generated files. See @docs/specs/openapi-workflow.md for the complete update and troubleshooting steps.

After generation:

```bash
(cd PeatedAPI && swift build && swift test)
(cd PeatedCore && swift build && swift test)
git diff --check
```

Fix compiler errors in `PeatedCore` and the app before doing anything else. Also compare endpoint names and data shapes, because the compiler cannot point out new endpoints that the app does not use yet.

## Update the design

Update shared styles before individual screens:

1. Add the named light and dark colors from `DESIGN.md` and `tokens.stylex.ts`.
2. Add the three fonts: Hanken Grotesk for headings, Karla for reading and controls, and IBM Plex Mono only for aligned technical data.
3. Match the 4-point spacing scale, 2/3-point corner radii, control heights, dividers, and shadows.
4. Update shared rows, fields, buttons, ratings, and lists before building screens from them.
5. Update one complete user flow at a time. Preserve iOS accessibility, Dynamic Type, safe areas, navigation, and touch targets instead of copying web interactions literally.
6. Compare each migrated screen with the corresponding web route and Storybook states in both light and dark appearances.

Do not treat the existing iOS design documentation as evidence that it still matches upstream. When upstream changes, update the iOS tokens and @docs/design/design-system.md in the same change.

## Verification

Run `make doctor` first, followed by the strongest relevant checks supported by the host. At minimum, run `make check` and lint changed files. On macOS, build and exercise affected flows using the standard `iPhone 16 Pro` simulator described in @docs/how-to/testing-strategy.md.
