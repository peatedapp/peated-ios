import SwiftUI

/// The one "more actions" control used everywhere content can be shared,
/// reported, or removed. Keep menu order the same on every screen: Share,
/// then friendship or ownership actions, then Report, then a destructive
/// action last after a `Divider`.
struct OverflowMenu<Content: View>: View {
    enum Placement {
        /// The end of a card's action row or a comment line.
        case inline
        /// A navigation bar trailing item.
        case toolbar
    }

    let placement: Placement
    /// A short noun for VoiceOver, such as "tasting" or "profile".
    let subject: String
    /// Replaces the icon with a spinner while one of the actions is running.
    var isBusy = false
    @ViewBuilder let content: Content

    init(_ placement: Placement, subject: String, isBusy: Bool = false, @ViewBuilder content: () -> Content) {
        self.placement = placement
        self.subject = subject
        self.isBusy = isBusy
        self.content = content()
    }

    var body: some View {
        Menu {
            content
        } label: {
            if isBusy {
                ProgressView().tint(.brand)
            } else {
                icon
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("More actions for this \(subject)")
    }

    @ViewBuilder
    private var icon: some View {
        switch placement {
        case .inline:
            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .light))
                .foregroundColor(.textSecondary)
                .frame(minWidth: 24, minHeight: 24)
        case .toolbar:
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.text)
        }
    }
}
