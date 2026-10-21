import PeatedCore
import SwiftUI

/// Every tasting of one bottle, newest first, loading more as the member scrolls.
/// Bottle detail shows only a short preview and links here.
struct BottleTastingsView: View {
    let bottleName: String?
    @Binding var path: NavigationPath

    @State private var tastings: PagedList<TastingFeedItem>

    init(bottleId: String, bottleName: String?, path: Binding<NavigationPath>) {
        self.bottleName = bottleName
        _path = path
        let repository = FeedRepository()
        _tastings = State(initialValue: PagedList(feature: "bottle_tastings") { cursor in
            try await repository.getBottleTastings(bottleId: bottleId, cursor: cursor)
        })
    }

    var body: some View {
        content
            .navigationTitle(bottleName ?? "Tastings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationChrome()
            .task {
                if !tastings.hasLoaded {
                    await tastings.reload()
                }
            }
            .screenBackground()
    }

    @ViewBuilder
    private var content: some View {
        if !tastings.hasLoaded, tastings.error == nil {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0 ..< 3) { _ in
                        SkeletonTastingCard()
                    }
                }
            }
        } else if let error = tastings.error, tastings.items.isEmpty {
            VStack(spacing: 12) {
                Text("Couldn't load tastings")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.footnote)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await tastings.reload() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if tastings.items.isEmpty {
            Text("No tastings yet")
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                ActivityList(
                    tastings: tastings.items,
                    showBottle: false,
                    onAppear: { tasting in
                        Task { await tastings.loadMoreIfNeeded(after: tasting) }
                    },
                    onToast: { tasting in
                        Task { await toggleToast(for: tasting.id) }
                    },
                    onComment: { tasting in
                        path.append(TastingActivityNavigationDestination.tasting(id: tasting.id, seed: tasting))
                    },
                    onUserTap: { tasting in
                        path.append(TastingActivityNavigationDestination.profile(
                            id: tasting.userId,
                            username: tasting.username,
                            pictureUrl: tasting.userAvatarUrl
                        ))
                    },
                    onBottleTap: { _ in
                        // Already showing this bottle's tastings.
                    }
                )

                PagedListFooter(list: tastings)
            }
            .refreshable {
                await tastings.reload()
            }
        }
    }

    private func toggleToast(for tastingId: String) async {
        guard let original = tastings.items.first(where: { $0.id == tastingId }) else { return }

        tastings.update(id: tastingId) { $0.updatingToast(to: !original.hasToasted) }

        do {
            let hasToasted = try await TastingRepository().toggleToast(tastingId: tastingId)
            tastings.update(id: tastingId) { _ in original.updatingToast(to: hasToasted) }
            if hasToasted {
                ToastManager.shared.showSuccess("Cheers! 🥃")
            }
        } catch {
            Telemetry.capture(error, feature: "bottle_tastings", operation: "toggle_toast")
            tastings.update(id: tastingId) { _ in original }
            ToastManager.shared.showError("Failed to update toast")
        }
    }
}
