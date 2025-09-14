Cache‑First Seed + SWR Refresh (2025)

Overview

- Goal: Render real content on the first frame using data we already have, then quietly refresh. Avoid all default placeholders and loading flashes when the information exists locally.

Principles

- Seed priority: navigation seed → in‑memory caches → DB cache → network.
- Prime gate: block default UI until a seed attempt completes (`isPrimed` or equivalent). Then show seeded UI immediately.
- SWR refresh: kick a background fetch; update view state and write‑through caches on success; keep seeded UI when refresh fails.
- Image warmup: prefetch derived images (avatar, hero, card) from seed/display.
- Notifications: post lightweight “XDataRefreshed(id:)” notifications for sibling views.

Standard View Model Shape

- Properties:
  - `isPrimed: Bool` – set true right after the seed/cache attempt (before network).
  - `state` – enum with `.loading` (only used when no seed/cache), `.loaded(Model)`, `.error`.
- Init:
  - Optional `seed` parameter of a lightweight type (e.g., `Bottle`, `Entity`, `TastingFeedItem`, or dedicated `Seed` struct).
- Methods:
  - `load()` – apply seed → read cache → set `isPrimed = true` → fire background refresh → write‑through cache and update state.

Navigation Contract

- When navigating from lists (feed/search/library), pass the row’s model (or minimal seed) to the destination view.
- Destination view accepts optional `seed` and forwards it to its view model.

Caching

- Write feed/list items to a keyed DB cache (e.g., `tasting_cache`) on fetch.
- Read by id in detail screens for instant seed.

Images

- On navigation and first render, call `ImagePrefetcher.prefetch(urls:)` for avatar/bottle/hero to eliminate flicker.

Error Handling

- Keep seeded UI on refresh failure; surface a small inline message or toast rather than collapsing to a global error state.

Checklist (per screen)

- [ ] Accept optional `seed` in view and view model constructors.
- [ ] Prime UI from seed; set `isPrimed = true` after attempting cache.
- [ ] Read from DB/normalized cache; update state if newer.
- [ ] Start background refresh; update state and write caches on success.
- [ ] Prefetch key images.
- [ ] Post `Notification.Name.XDataRefreshed` on refresh.

Current Usage

- Tasting Detail: seed from DB cache (feed writes), comments refresh in background.
- Profile: cache‑prime gate added; seeds from auth/current user and store; proposing explicit seed on navigation where available.
- Bottle Detail: accepts optional `seed`; model displays seed first, then cache/network.
- Entity Detail: accepts optional `seed`; model displays seed first, then cache/network.

Next Targets

- Pass explicit seeds from Feed/Search/Library into detail views.
- Migrate remaining screens with segmented controls to custom tabs (better dark blending) and apply the same seed flow.

