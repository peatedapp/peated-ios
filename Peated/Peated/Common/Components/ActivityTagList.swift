import SwiftUI

/// Up to four tasting notes as small chips, plus a "+N more" chip, wrapping like the web.
struct ActivityTagList: View {
    let tags: [String]

    private static let maxVisibleNotes = 4

    private var visibleTags: [String] {
        Array(tags.prefix(Self.maxVisibleNotes))
    }

    private var hiddenCount: Int {
        tags.count - visibleTags.count
    }

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(Array(visibleTags.enumerated()), id: \.offset) { _, tag in
                ActivityChip(text: tag)
            }
            if hiddenCount > 0 {
                ActivityChip(text: "+\(hiddenCount) more")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tasting notes: \(tags.joined(separator: ", "))")
    }
}

/// A static small chip: 13pt semibold muted text inside a hairline outline.
struct ActivityChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.peatedInteractiveSmall)
            .foregroundColor(.textSecondary)
            .lineLimit(1)
            .padding(.vertical, 2)
            .padding(.horizontal, 8)
            .frame(minHeight: 24)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .stroke(Color.sectionRule, lineWidth: 1)
            )
    }
}
