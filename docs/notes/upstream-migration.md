# Upstream Migration

Status: shared groundwork complete; more features remain

This note records the initial scope for bringing the iOS app up to date with Peated's production API and redesigned web product.

## Baseline

The first review was performed on 2026-09-05 using:

- `peated-ios` commit `8ff65feb27dff96395e6761e5f57606ab88f5860`
- backend/web `origin/main` commit `64e6e2d72a9e32ee73e4d928b5985e30256af6f8`
- the live production document at `https://api.peated.com/spec.json`

Refresh these inputs before starting more work. Follow @docs/how-to/sync-peated-upstream.md; do not assume the hashes above remain current.

## API changes

The previous iOS OpenAPI document had 141 paths and 186 operations. Production had 115 paths and 135 operations at the time of the review. Some endpoints were added and others removed, making this a breaking API update rather than a routine client refresh.

Changes that affect the iOS app include:

- Tastings now store one of five bands—Mediocre, Good, Very good, Outstanding, or Unicorn—instead of Pass, Sip, and Savor numeric values.
- Member reviews are separate from tastings and use a whole-number score from 0–100 for a specific bottle.
- Bottle responses and creation include more release and maturation details, bottle groups and series, rating summaries, and more filters.
- Bottle recommendations, create candidates, aliases, barcodes, prices, tags, and flavor-profile endpoints are available.
- Entities have one explicit type and endpoints for portfolios, aliases, events, following, matching, categories, catalogs, and flavor profiles.
- Search returns grouped catalog results, exact matches, and nearest matches across more catalog kinds.
- Brands, bottlers, companies, distilleries, external reviews, and richer country and region data have public list or detail endpoints.
- Several admin, audit, repair, price-queue, and legacy review operations present in the checked-in spec are absent from production.

The production client has now been regenerated. `PeatedAPI` builds and its decoding test passes. The app code compiles against it, including the new file-upload format for tasting images and bottle photo identification.

The first update also moved tastings and saved offline actions to the five new ratings, added the current bottle details and rating summaries, updated entity, search, and library data, and added a database update for saved tasting ratings. The old numeric rating column remains in existing databases so upgrades stay safe, but the app no longer reads or writes it.

## Design changes

The current upstream visual system is defined by `../peated/DESIGN.md` and `../peated/apps/web/src/styles/tokens.stylex.ts`.

The main design differences were:

- System-selected light and dark schemes replace the forced dark slate presentation.
- The primary palette uses ground `#F7F8F5`/`#101210`, surface `#EBEEE7`/`#1B1E1A`, inset `#DCE0D6`/`#2B2F29`, ink `#161914`/`#E8EAE3`, and accent `#9A5B12`/`#D9922F`.
- Hanken Grotesk is used for headings, Karla for reading and controls, and IBM Plex Mono only for aligned technical data.
- Spacing uses 4, 8, 12, 16, 24, 32, and 48 points.
- Controls use 3-point corners; tags, image slots, and bar segments use 2-point corners. Fully rounded controls and the current 8–12 point card corners are not part of the new system.
- Pages favor simple sections, clear type, and thin dividers over filled cards. Shadows are limited to content shown above the page.
- Peated is primarily a whisky reference, so screens should put bottle information before social activity.

The shared light and dark colors, system appearance setting, compact corners, heading styles, bottle image sizes, rating controls, and main search → bottle → tasting screens are now updated. The Hanken Grotesk and Karla font files are not present in the backend/web checkout, so iOS currently uses similar system fonts. Adding the real font files and simplifying the remaining screens are follow-up work.

## Migration order

1. **Complete:** regenerate `PeatedAPI` and update tasting creation, display, and storage for the five new ratings.
2. **Complete:** update bottle, entity, search, library, profile, and activity data for the current API responses.
3. **In progress:** update colors, fonts, spacing, corners, dividers, controls, and shadows. The actual web font files still need to be found and added to the app.
4. **In progress:** update shared rows, ratings, fields, buttons, filters, lists, loading screens, empty screens, and errors from the web examples.
5. **In progress:** update complete user flows, beginning with the app shell and search → bottle → tasting path.
6. **Next:** add member reviews and other new features after the shared bottle and rating work is complete.
7. **Ongoing:** verify each update in light and dark appearances, Dynamic Type sizes, narrow screens, and VoiceOver, in addition to unit and integration tests.

Update this note as work lands. Remove completed notes instead of keeping outdated implementation details.
