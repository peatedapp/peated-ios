# Tasting Confirmation

Status: active

The final creation step lets the user review the tasting that will be posted before submitting it to Peated.

## Presented information

The preview reflects the data collected by the preceding steps:

- selected bottle and brand;
- Pass, Sip, or Savor rating;
- tasting notes and tags;
- selected photo previews;
- serving style; and
- the selected location or At Home state, which is currently preview-only because the API does not accept it.

The flow's Back action returns to earlier steps for edits. Submitting creates the tasting, then uploads the first selected photo. A photo-upload failure is non-fatal so an otherwise valid tasting is not lost.

## Sharing and privacy

The create-tasting API does not currently accept per-tasting privacy or external social-network fields. The confirmation screen therefore does not present controls for those unsupported behaviors.

After creation, users can share a tasting through the native system share sheet from its tasting actions. Per-tasting privacy or direct social-network integrations should only be added when the API and app can honor the selection end to end.

## Failure behavior

- Creation failures keep the flow open and show the API error.
- Photo compression or upload failures do not fail the tasting itself.
- Submission disables duplicate work until the request completes.

## Implementation

- UI: `Peated/Peated/Features/CreateTasting/Steps/ConfirmationStep.swift`
- State and submission: `Peated/Peated/Features/CreateTasting/CreateTastingViewModel.swift`
- API mapping: `PeatedCore/Sources/PeatedCore/Repositories/TastingRepository.swift`
