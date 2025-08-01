# Tasting Detail Screen

## Overview

The Tasting Detail screen provides a full view of a single tasting, including all toasts, the complete comment thread, and additional actions. Users can interact with the tasting and engage in discussions.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  ← Back                          •••    │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────┐     │
│  │  [Full TastingCard]           │     │
│  │  John is drinking Ardbeg 10   │     │
│  │  @ The Whisky Bar • 2h ago    │     │
│  │  ★★★★☆ 4.5                   │     │
│  │  "Intense peat smoke..."      │     │
│  │  [Photo Gallery]              │     │
│  │  🥃 23 Toasts  💬 5 Comments │     │
│  └───────────────────────────────┘     │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Toasts (23)                           │
│  ┌─────────────────────────────────┐   │
│  │ [Avatar] Sarah L. and 22 others │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Comments                               │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [Avatar] Mike Chen • 1h ago     │   │
│  │ Great choice! How does it       │   │
│  │ compare to the Uigeadail?       │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [Avatar] John (OP) • 45m ago    │   │
│  │ @Mike More intense peat but     │   │
│  │ less sherry influence           │   │
│  └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │  Add a comment...               │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct TastingDetailScreen: View {
    let tastingId: String
    @StateObject private var viewModel: TastingDetailViewModel
    @State private var commentText = ""
    @State private var showingToastList = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @FocusState private var isCommentFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(tastingId: String) {
        self.tastingId = tastingId
        self._viewModel = StateObject(wrappedValue: TastingDetailViewModel(tastingId: tastingId))
    }
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingView
                
            case .loaded(let tasting):
                loadedView(tasting)
                
            case .error(let message):
                errorView(message)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.tasting?.user?.id == currentUserId {
                    Menu {
                        Button(action: { showingShareSheet = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            await viewModel.loadTasting()
        }
        .sheet(isPresented: $showingToastList) {
            if let tasting = viewModel.tasting {
                ToastListView(tasting: tasting)
            }
        }
        .confirmationDialog("Delete Tasting", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteTasting()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this tasting? This cannot be undone.")
        }
    }
    
    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                TastingCardSkeleton()
                    .padding(.horizontal)
                
                ForEach(0..<3) { _ in
                    CommentSkeleton()
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Loaded View
    @ViewBuilder
    private func loadedView(_ tasting: Tasting) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Full tasting card
                    TastingCard(
                        tasting: tasting,
                        showFullNotes: true,
                        onToast: { _ in
                            Task {
                                await viewModel.toggleToast()
                            }
                        },
                        onProfile: { user in
                            // Navigate to profile
                        },
                        onBottle: { bottle in
                            // Navigate to bottle
                        }
                    )
                    .padding()
                    .allowsHitTesting(true)
                    
                    Divider()
                        .padding(.vertical, 16)
                    
                    // Toasts section
                    toastsSection(tasting)
                        .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 16)
                    
                    // Comments section
                    commentsSection
                        .padding(.horizontal)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            Divider()
            
            // Comment input
            commentInputView
        }
    }
    
    // MARK: - Toasts Section
    @ViewBuilder
    private func toastsSection(_ tasting: Tasting) -> some View {
        Button(action: { showingToastList = true }) {
            HStack {
                Text("Toasts")
                    .font(.headline)
                
                Text("(\(tasting.toastCount))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if tasting.toastCount > 0 {
                    // Show first few toast avatars
                    HStack(spacing: -8) {
                        ForEach(tasting.toasts.prefix(5)) { toast in
                            UserAvatar(user: toast.user, size: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemBackground), lineWidth: 2)
                                )
                        }
                        
                        if tasting.toastCount > 5 {
                            Text("+\(tasting.toastCount - 5)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Comments Section
    @ViewBuilder
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Comments")
                    .font(.headline)
                
                if !viewModel.comments.isEmpty {
                    Text("(\(viewModel.comments.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if viewModel.comments.isEmpty {
                Text("No comments yet. Be the first!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.comments) { comment in
                    CommentView(
                        comment: comment,
                        isOP: comment.user?.id == viewModel.tasting?.user?.id,
                        onProfile: { user in
                            // Navigate to profile
                        },
                        onDelete: comment.user?.id == currentUserId ? {
                            Task {
                                await viewModel.deleteComment(comment)
                            }
                        } : nil
                    )
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Comment Input
    @ViewBuilder
    private var commentInputView: some View {
        HStack(spacing: 12) {
            HStack {
                TextField("Add a comment...", text: $commentText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isCommentFieldFocused)
                
                if !commentText.isEmpty {
                    Button(action: {
                        Task {
                            await postComment()
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .disabled(viewModel.isPostingComment)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Error View
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to load tasting")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await viewModel.loadTasting()
                }
            }) {
                Text("Try Again")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    private func postComment() async {
        let text = commentText
        commentText = ""
        isCommentFieldFocused = false
        
        await viewModel.postComment(text)
    }
}

// MARK: - Comment View
struct CommentView: View {
    let comment: Comment
    let isOP: Bool
    let onProfile: (User) -> Void
    let onDelete: (() -> Void)?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Button(action: { onProfile(comment.user!) }) {
                    UserAvatar(user: comment.user, size: 32)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(comment.user?.displayName ?? comment.user?.username ?? "")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if isOP {
                            Text("OP")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(.accentColor)
                                .cornerRadius(4)
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(comment.createdAt.relativeTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(comment.text)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if onDelete != nil {
                    Menu {
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .confirmationDialog("Delete Comment", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        }
    }
}

// MARK: - Toast List View
struct ToastListView: View {
    let tasting: Tasting
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(tasting.toasts) { toast in
                HStack {
                    UserAvatar(user: toast.user, size: 44)
                    
                    VStack(alignment: .leading) {
                        Text(toast.user?.displayName ?? toast.user?.username ?? "")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("@\(toast.user?.username ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if toast.user?.id != currentUserId {
                        FollowButton(user: toast.user!, style: .compact)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Toasts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - View Model
@MainActor
class TastingDetailViewModel: ObservableObject {
    @Published var state: ViewState = .loading
    @Published var tasting: Tasting?
    @Published var comments: [Comment] = []
    @Published var isPostingComment = false
    
    private let tastingId: String
    private let repository: TastingRepository
    
    enum ViewState {
        case loading
        case loaded(Tasting)
        case error(String)
    }
    
    init(tastingId: String, repository: TastingRepository = TastingRepositoryImpl()) {
        self.tastingId = tastingId
        self.repository = repository
    }
    
    func loadTasting() async {
        state = .loading
        
        do {
            let tasting = try await repository.getTasting(id: tastingId)
            self.tasting = tasting
            self.comments = tasting.comments.sorted { $0.createdAt < $1.createdAt }
            state = .loaded(tasting)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func toggleToast() async {
        guard let tasting = tasting else { return }
        
        // Optimistic update
        withAnimation {
            self.tasting?.hasToasted.toggle()
            self.tasting?.toastCount += self.tasting?.hasToasted == true ? 1 : -1
        }
        
        do {
            if tasting.hasToasted {
                try await repository.removeToast(tastingId: tastingId)
            } else {
                try await repository.addToast(tastingId: tastingId)
            }
        } catch {
            // Revert on error
            withAnimation {
                self.tasting?.hasToasted.toggle()
                self.tasting?.toastCount += self.tasting?.hasToasted == true ? 1 : -1
            }
        }
    }
    
    func postComment(_ text: String) async {
        isPostingComment = true
        
        do {
            let comment = try await repository.addComment(
                tastingId: tastingId,
                text: text
            )
            
            withAnimation {
                comments.append(comment)
                tasting?.commentCount += 1
            }
        } catch {
            // Show error
        }
        
        isPostingComment = false
    }
    
    func deleteComment(_ comment: Comment) async {
        // Optimistic removal
        withAnimation {
            comments.removeAll { $0.id == comment.id }
            tasting?.commentCount -= 1
        }
        
        do {
            try await repository.deleteComment(
                tastingId: tastingId,
                commentId: comment.id
            )
        } catch {
            // Revert on error
            withAnimation {
                comments.append(comment)
                comments.sort { $0.createdAt < $1.createdAt }
                tasting?.commentCount += 1
            }
        }
    }
    
    func deleteTasting() async {
        do {
            try await repository.deleteTasting(id: tastingId)
        } catch {
            // Show error
        }
    }
}
```

## Navigation

### Entry Points
- Tap tasting card in feed
- Deep link to specific tasting
- Push notification for comments/toasts

### Exit Points
- Back button → Previous screen
- Delete tasting → Pop to feed
- User profile taps
- Bottle detail tap

## Features

### Toast Management
- View all users who toasted
- Follow users from toast list
- Real-time count updates

### Comment Thread
- Chronological comment display
- OP (Original Poster) badge
- Delete own comments
- @mention support (future)

### Actions
- Share tasting externally
- Delete own tasting
- Report inappropriate content

## Data Requirements

### API Endpoints
- `GET /tastings/{id}` - Full tasting details
- `POST /tastings/{id}/comments` - Add comment
- `DELETE /tastings/{id}/comments/{commentId}` - Delete comment
- `DELETE /tastings/{id}` - Delete tasting

### Data Loading
- Load tasting with embedded comments
- Paginate comments if > 50
- Real-time updates via polling

## UI Components

### Comment Input
- Expandable text field (1-4 lines)
- Send button appears with text
- Keyboard avoidance
- Character limit (500)

### Comment Display
- User avatar and name
- Relative timestamps
- OP indicator
- Delete option for own comments

## Accessibility

- VoiceOver support for all actions
- Comment navigation
- Action announcements
- Keyboard shortcuts

## Performance

- Lazy load comments
- Image caching
- Smooth scrolling
- Optimistic updates

## Error Handling

- Network failures
- Deleted tasting (404)
- Permission errors
- Rate limiting