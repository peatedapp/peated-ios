# SwiftUI and Accessibility

## Intent

Views should make workflow, state, navigation, and accessibility ownership clear where the UI is rendered.

## Policy

- Keep local presentation state in the view. Move shared workflow and domain behavior to the owning observable model or service.
- Reuse existing Peated fields, buttons, cards, selectors, loading states, empty states, and error states before adding a new pattern.
- Extract a component when it owns repeated behavior or presentation, not only to reduce line count.
- Every actionable control needs an accessible name, role, state, and usable target size.
- Support Dynamic Type. Do not encode fixed heights that clip localized or accessibility-sized text.
- Preserve parent navigation and context for nested workflows unless the screen is deliberately standalone.
- Empty, loading, offline, and failure states must explain what is happening and provide the next useful action when one exists.
- Verify changed screens on the standard iPhone simulator. Also check the smallest supported iPhone, iPad layout, VoiceOver, and large text when the change can affect them.
- Prefer semantic queries and accessibility identifiers in UI tests. Do not depend on screen coordinates.

## Exceptions

Pure decorative images do not need spoken labels. Platform and third-party surfaces may limit accessibility control; document and test the behavior Peated owns.
