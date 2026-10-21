import PeatedCore
import SwiftUI

/// The "Is it already on Peated?" review: the draft, then existing bottles that may match it.
/// Wording matches the web form.
struct BottleCreateCandidateReview: View {
    let draft: Bottle
    let results: [Bottle]
    let onUse: (Bottle) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BottleCandidateIdentity(bottle: draft)

            Text("If one of these is the same bottle, use it instead of adding another.")
                .font(.peatedBody)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(results) { bottle in
                    row(bottle)
                        .padding(.vertical, 8)

                    if bottle.id != results.last?.id {
                        Divider()
                    }
                }
            }
            .overlay(alignment: .top) { Divider() }
            .overlay(alignment: .bottom) { Divider() }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Bottles that may match")
        }
    }

    @ViewBuilder
    private func row(_ bottle: Bottle) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))

        layout {
            BottleCandidateIdentity(bottle: bottle)

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }

            Button("Use this bottle") {
                onUse(bottle)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.brand)
            .accessibilityLabel("Use this bottle: \(bottle.fullName)")
        }
    }
}

/// A bottle's thumbnail and identity lines, read by VoiceOver as one element.
private struct BottleCandidateIdentity: View {
    let bottle: Bottle

    private var identity: BottleIdentity {
        BottleIdentity(bottle: bottle)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ActivityBottleThumbnail(imageUrl: bottle.imageUrl)

            VStack(alignment: .leading, spacing: 2) {
                Text(identity.name)
                    .font(.peatedRowTitle)
                    .tracking(DesignSystem.Tracking.rowTitle)
                    .foregroundColor(.text)
                    .fixedSize(horizontal: false, vertical: true)

                if !identity.provenance.isEmpty {
                    Text(identity.provenance.joined(separator: " · "))
                        .font(.peatedMetadata)
                        .foregroundColor(.textSecondary)
                }

                if !identity.metadata.isEmpty {
                    Text(identity.metadata.joined(separator: " · "))
                        .font(.peatedMetadata)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
