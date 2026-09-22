import PeatedCore
import SwiftUI

/// The block list under Settings. Each row can lift its block right away.
struct BlockedUsersView: View {
    @State private var model = BlockedUsersModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch model.state {
                case .loading:
                    ProgressView()
                        .tint(.brand)
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .accessibilityLabel("Loading blocked members")
                case let .loaded(users):
                    if users.isEmpty {
                        emptyState
                    } else {
                        FormSection {
                            ForEach(users) { blocked in
                                row(blocked)
                            }
                        }
                    }
                case let .error(message):
                    errorState(message)
                }
            }
            .padding(.vertical)
        }
        .navigationChrome()
        .navigationTitle("Blocked Members")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .task {
            await model.load()
        }
    }

    private func row(_ blocked: BlockedUser) -> some View {
        HStack(spacing: 12) {
            AvatarImage(urlString: blocked.user.pictureUrl, size: 36)
                .accessibilityHidden(true)

            Text("@\(blocked.user.username)")
                .font(.peatedBody)
                .foregroundColor(.text)
                .lineLimit(1)

            Spacer()

            if model.unblockingUserIds.contains(blocked.id) {
                ProgressView()
                    .tint(.brand)
                    .frame(width: 72)
                    .accessibilityLabel("Unblocking")
            } else {
                Button("Unblock") {
                    Task { await model.unblock(blocked) }
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.surface)
                .clipShape(Capsule())
                .buttonStyle(.plain)
                .accessibilityLabel("Unblock @\(blocked.user.username)")
            }
        }
        .frame(minHeight: 44)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.raised")
                .font(.system(size: 32))
                .foregroundColor(.textSecondary)
                .accessibilityHidden(true)
            Text("No blocked members")
                .font(.headline)
                .foregroundColor(.text)
            Text("Block a member from their profile to stop them commenting on, toasting, or friending you.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 40)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await model.load() }
            }
            .foregroundColor(.brand)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 40)
    }
}

#Preview {
    NavigationStack {
        BlockedUsersView()
    }
}
