# Library Screen

Status: active

The Library is the signed-in user's saved bottle collection, with status filtering, search, and direct navigation to bottle details.

## Layout

The screen contains:

- a native search field in the navigation area;
- horizontal All, Sealed, Open, and Empty filter chips; and
- a vertically scrolling list of matching bottles.

Each bottle row emphasizes the bottle image, name, brand, and category. Library status remains available through the filter chips, but is not repeated on every row. Membership and tasted indicators are omitted from the trailing edge because the surrounding context already communicates Library membership and the icons do not affect navigation.

## Search

Search is sent to the collection API together with the selected status filter. Input is trimmed and debounced before loading so typing does not issue a request for every keystroke. Clearing search restores the full selected status view.

An empty search result uses a dedicated no-results message. An empty unfiltered Library instead explains how to save bottles from bottle details.

## Loading and errors

- The initial load shows the Library skeleton. Later searches, filter changes, and refreshes preserve the current
  content and show a compact progress indicator instead of replacing the screen.
- Pull to refresh repeats the current search and status request.
- Errors preserve a Retry action for the current request.
- Cancelled and overlapping loads are ignored so rapid typing cannot surface an error or let stale responses replace
  newer search results.
- Empty search and filtered states provide an action to clear the search or return to all bottles.

## Navigation

Selecting a row opens bottle detail with the row's bottle data as a seed, allowing immediate content while full details refresh.

## Implementation

- UI and state: `Peated/Peated/Features/Library/LibraryView.swift`
- Shared bottle row: `Peated/Peated/Common/Components/BottleRow.swift`
- API integration: `PeatedCore/Sources/PeatedCore/Repositories/CollectionRepository.swift`
