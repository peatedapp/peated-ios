import PeatedCore
import SwiftUI

/// The overflow menu on another member's profile: friendship, report, and block.
struct ProfileActionsMenu: View {
    let target: User
    let model: ProfileModel
    @Binding var showingBlockConfirmation: Bool

    var body: some View {
        OverflowMenu(.toolbar, subject: "profile", isBusy: model.isTogglingFriend || model.isUpdatingBlock) {
            // A block ends friendship on the server, so friend actions only show for unblocked members.
            if !model.isBlocked {
                friendshipButton
            }

            ReportMenuItem(target: .user(id: target.id, username: target.username))

            Divider()

            if model.isBlocked {
                Button {
                    Task { await model.unblock() }
                } label: {
                    Label("Unblock", systemImage: "hand.raised.slash")
                }
            } else {
                Button(role: .destructive) {
                    showingBlockConfirmation = true
                } label: {
                    Label("Block", systemImage: "hand.raised")
                }
            }
        }
    }

    private var friendshipButton: some View {
        let isConnected = target.friendStatus == .friends || target.friendStatus == .pending
        return Button(role: isConnected ? .destructive : .none) {
            Task { await model.toggleFriendship() }
        } label: {
            if target.friendStatus == .friends {
                Label("Unfriend", systemImage: "person.fill.xmark")
            } else if target.friendStatus == .pending {
                Label("Remove Friend", systemImage: "person.fill.xmark")
            } else {
                Label("Add Friend", systemImage: "person.badge.plus")
            }
        }
    }
}
