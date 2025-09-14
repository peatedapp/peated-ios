import SwiftUI
import PeatedCore

struct TastingDetailView: View {
  let tastingId: String
  let seed: TastingFeedItem?
  let onNavigateToProfile: ((String) -> Void)?
  let onNavigateToBottle: ((String) -> Void)?
  
  @State private var model: TastingDetailModel
  @State private var commentText = ""
  @State private var showingDeleteAlert = false
  @FocusState private var isCommentFieldFocused: Bool
  @Environment(\.dismiss) private var dismiss
  
  init(tastingId: String, seed: TastingFeedItem? = nil, onNavigateToProfile: ((String) -> Void)? = nil, onNavigateToBottle: ((String) -> Void)? = nil) {
    self.tastingId = tastingId
    self.seed = seed
    self.onNavigateToProfile = onNavigateToProfile
    self.onNavigateToBottle = onNavigateToBottle
    self._model = State(initialValue: TastingDetailModel(tastingId: tastingId, seed: seed))
  }
  
  var body: some View {
    Group {
      switch model.state {
      case .loading:
        loadingView
        
      case .loaded(let tasting):
        loadedView(tasting)
          .task(id: tasting.id) {
            prefetchDetailImages(tasting)
          }
        
      case .error(let message):
        errorView(message)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        if let tasting = model.tasting,
           tasting.userId == AuthenticationManager.shared.currentUser?.id {
          Menu {
            Button {
              // TODO: Implement share
            } label: {
              Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button(role: .destructive) {
              showingDeleteAlert = true
            } label: {
              Label("Delete", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
              .foregroundColor(.text)
          }
        }
      }
    }
    .task {
      await model.loadTasting()
    }
    // Removed toast list sheet
    .confirmationDialog("Delete Tasting", isPresented: $showingDeleteAlert) {
      Button("Delete", role: .destructive) {
        Task {
          do {
            try await model.deleteTasting()
            dismiss()
          } catch {
            ToastManager.shared.showError("Failed to delete tasting")
          }
        }
      }
    } message: {
      Text("Are you sure you want to delete this tasting? This cannot be undone.")
    }
    .screenBackground()
  }

  private func prefetchDetailImages(_ tasting: TastingDetail) {
    var urls: [URL] = []
    if let s = tasting.userAvatarUrl, let u = URL(string: s) { urls.append(u) }
    if let s = tasting.bottleImageUrl, let u = URL(string: s) { urls.append(u) }
    if let s = tasting.imageUrl, let u = URL(string: s) { urls.append(u) }
    ImagePrefetcher.prefetch(urls: urls, max: 3)
  }
  
  // MARK: - Loading View
  
  @ViewBuilder
  private var loadingView: some View {
    ScrollView {
      VStack(spacing: 16) {
        // Tasting card skeleton
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.surface)
          .frame(height: 300)
          .shimmer()
        
        // Comment skeletons
        ForEach(0..<3, id: \.self) { _ in
          HStack(alignment: .top, spacing: 12) {
            Circle()
              .fill(Color.surface)
              .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 8) {
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.surface)
                .frame(width: 120, height: 14)
              
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.surface)
                .frame(height: 40)
            }
          }
          .shimmer()
        }
      }
      .padding()
    }
  }
  
  // MARK: - Loaded View
  
  @ViewBuilder
  private func loadedView(_ tasting: TastingDetail) -> some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          // Full tasting card using the feed card design
          TastingFeedCard(
            tasting: tasting.toFeedItem(),
            onToast: {
              Task {
                await model.toggleToast()
              }
            },
            onComment: {
              // Focus comment field
              isCommentFieldFocused = true
            },
            onUserTap: {
              onNavigateToProfile?(tasting.userId)
            },
            onBottleTap: {
              // Navigate to bottle detail
              onNavigateToBottle?(tasting.bottleId)
            }
          )
          
          // Removed standalone toasts section
          
          // Comments section
          commentsSection(tasting)
            .padding(.horizontal)
        }
      }
      .scrollDismissesKeyboard(.interactively)
      
      Divider()
      
      // Comment input
      commentInputView
    }
  }
  
  // Removed toasts section
  
  // MARK: - Comments Section
  
  @ViewBuilder
  private func commentsSection(_ tasting: TastingDetail) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Comments")
          .font(.peatedHeadline)
          .foregroundColor(.text)
        
        if case .loaded(let comments) = model.commentState, !comments.isEmpty {
          Text("(\(comments.count))")
            .font(.peatedSubheadline)
            .foregroundColor(.textSecondary)
        }
        
        Spacer()
      }
      
      // Handle different comment states
      switch model.commentState {
      case .loading:
        // Show loading skeleton for comments
        ForEach(0..<2, id: \.self) { _ in
          HStack(alignment: .top, spacing: 12) {
            Circle()
              .fill(Color.surface)
              .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 8) {
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.surface)
                .frame(width: 120, height: 14)
              
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.surface)
                .frame(height: 40)
            }
          }
          .shimmer()
        }
        
      case .loaded(let comments):
        if comments.isEmpty {
          Text("No comments yet. Be the first!")
            .font(.peatedBody)
            .foregroundColor(.textSecondary)
            .padding(.vertical, 20)
        } else {
          ForEach(comments) { comment in
            CommentView(
              comment: comment,
              isOP: comment.userId == tasting.userId,
              onProfile: { userId in
                onNavigateToProfile?(userId)
              },
              onDelete: comment.userId == AuthenticationManager.shared.currentUser?.id ? {
                Task {
                  await model.deleteComment(comment)
                }
              } : nil
            )
          }
        }
        
      case .error(let message):
        // Show error state for comments only
        VStack(spacing: 8) {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 24))
            .foregroundColor(.warning)
          
          Text("Failed to load comments")
            .font(.peatedSubheadline)
            .foregroundColor(.text)
          
          Button {
            Task {
              await model.loadComments()
            }
          } label: {
            Text("Try Again")
              .font(.peatedCaption)
              .foregroundColor(.brand)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
      }
    }
    .padding(.bottom, 20)
  }
  
  // MARK: - Comment Input
  
  @ViewBuilder
  private var commentInputView: some View {
    HStack(spacing: 12) {
      HStack(spacing: 8) {
        TextEditor(text: $commentText)
          .font(.peatedBody)
          .foregroundColor(.text)
          .frame(minHeight: 20, maxHeight: 80)
          .focused($isCommentFieldFocused)
          .background(Color.clear)
          .overlay(alignment: .topLeading) {
            if commentText.isEmpty && !isCommentFieldFocused {
              Text("Add a comment...")
                .foregroundColor(.textMuted)
                .padding(.top, 2)
            }
          }

        if !commentText.isEmpty {
          Button {
            Task { await postComment() }
          } label: {
            Image(systemName: "arrow.up.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.brand)
          }
          .disabled(model.isPostingComment)
        }
      }
      .inputBox(state: isCommentFieldFocused ? .focused : .normal, cornerRadius: 20, horizontalPadding: 16, verticalPadding: 10)
    }
    .padding(.vertical, 8)
    .background(Color.background)
  }
  
  // MARK: - Error View
  
  @ViewBuilder
  private func errorView(_ message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 50))
        .foregroundColor(.warning)
      
      Text("Unable to load tasting")
        .font(.peatedTitle3)
        .fontWeight(.semibold)
        .foregroundColor(.text)
      
      Text(message)
        .font(.peatedBody)
            .foregroundColor(.textSecondary)
        .multilineTextAlignment(.center)
      
      Button {
        Task {
          await model.loadTasting()
        }
      } label: {
        Text("Try Again")
          .font(.peatedBody)
          .fontWeight(.medium)
          .foregroundColor(.onBrand)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .background(Color.brand)
          .cornerRadius(20)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  // MARK: - Actions
  
  private func postComment() async {
    let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    
    commentText = ""
    isCommentFieldFocused = false
    
    await model.postComment(text)
  }
}

// MARK: - Tasting Detail Card

struct TastingDetailCard: View {
  let tasting: TastingDetail
  let onToast: () async -> Void
  let onUserTap: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header with bottle info
      HStack(alignment: .top, spacing: 12) {
        // Bottle image
        BottleImage(imageUrl: tasting.bottleImageUrl)
          .frame(width: 60, height: 80)
          .background(Color.surface)
          .clipShape(RoundedRectangle(cornerRadius: 8))
        
        VStack(alignment: .leading, spacing: 4) {
          Text(tasting.bottleName)
            .font(.peatedDisplaySerif)
            .foregroundColor(.text)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.98)
          
          HStack(spacing: 4) {
            Text(tasting.bottleBrandName)
              .font(.peatedSubheadline)
              .foregroundColor(.textSecondary)
            
            if let category = tasting.bottleCategory {
              Text("•")
                .font(.peatedSubheadline)
                .foregroundColor(.textMuted)
              
              Text(category.capitalized)
                .font(.peatedSubheadline)
                .foregroundColor(.textSecondary)
            }
          }
          
          // Rating
          HStack(spacing: 4) {
            ForEach(0..<5) { index in
              Image(systemName: index < Int(tasting.rating) ? "star.fill" : "star")
                .font(.system(size: 14))
                .foregroundColor(.brand)
            }
            
            Text(String(format: "%.1f", tasting.rating))
              .font(.peatedBody)
              .fontWeight(.medium)
              .foregroundColor(.text)
          }
          .padding(.top, 4)
        }
        
        Spacer()
      }
      
      // Notes (full, not truncated)
      if let notes = tasting.notes, !notes.isEmpty {
        Text(notes)
          .font(.peatedBody)
          .italic()
          .foregroundColor(.text)
          .fixedSize(horizontal: false, vertical: true)
      }
      
      // Tags (muted style)
      if !tasting.tags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(tasting.tags, id: \.self) { tag in
              Text("#\(tag)")
                .font(.peatedFootnote)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.surfaceSubtle)
                .clipShape(Capsule())
            }
          }
        }
      }
      
      // Tasting photo
      if let imageUrl = tasting.imageUrl, let url = URL(string: imageUrl) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(maxHeight: 300)
              .clipped()
              .clipShape(RoundedRectangle(cornerRadius: 12))
          case .failure, .empty:
            EmptyView()
          @unknown default:
            ProgressView()
              .frame(height: 200)
          }
        }
      }
      
      // User info and actions
      HStack {
        // User avatar and info
        HStack(spacing: 8) {
          AvatarImage(urlString: tasting.userAvatarUrl, size: 32)
          
          VStack(alignment: .leading, spacing: 2) {
            Text(tasting.authorDisplayName)
              .font(.peatedSubheadline)
              .fontWeight(.medium)
              .foregroundColor(.text)
            
            Text("@\(tasting.username) • \(tasting.timeAgo)")
              .font(.peatedCaption)
              .foregroundColor(.textSecondary)
          }
        }
        .contentShape(Rectangle())
        .onTapGesture {
          onUserTap()
        }
        
        Spacer()
        
        // Toast action
        Button {
          Task {
            await onToast()
          }
        } label: {
          HStack(spacing: 4) {
            Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
              .font(.system(size: 16))
            Text("\(tasting.toastCount)")
              .font(.peatedSubheadline)
          }
          .foregroundColor(tasting.hasToasted ? .brand : .textSecondary)
        }
      }
    }
    .padding()
    .background(Color.surface)
    .cornerRadius(12)
  }
}

// MARK: - Comment View

struct CommentView: View {
  let comment: Comment
  let isOP: Bool
  let onProfile: (String) -> Void
  let onDelete: (() -> Void)?
  @State private var showingDeleteAlert = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top, spacing: 12) {
        // User avatar
        Button {
          onProfile(comment.userId)
        } label: {
          AvatarImage(urlString: comment.userAvatarUrl, size: 32)
        }
        
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(comment.authorDisplayName)
              .font(.peatedSubheadline)
              .fontWeight(.semibold)
              .foregroundColor(.text)
            
            if isOP {
              Text("OP")
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.brand.opacity(0.2))
                .foregroundColor(.brand)
                .cornerRadius(4)
            }
            
            Text("•")
              .font(.peatedCaption)
              .foregroundColor(.textMuted)
            
            Text(comment.timeAgo)
              .font(.peatedCaption)
              .foregroundColor(.textSecondary)
          }
          
          Text(comment.text)
            .font(.peatedBody)
            .italic()
            .foregroundColor(.text)
            .fixedSize(horizontal: false, vertical: true)
        }
        
        Spacer()
        
        if onDelete != nil {
          Menu {
            Button(role: .destructive) {
              showingDeleteAlert = true
            } label: {
              Label("Delete", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis")
              .font(.peatedCaption)
              .foregroundColor(.textSecondary)
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

// Removed ToastListView

// MARK: - Shimmer Effect

extension View {
  func shimmer() -> some View {
    self
      .redacted(reason: .placeholder)
      .shimmering()
  }
}

struct ShimmeringView: ViewModifier {
  @State private var phase: CGFloat = 0
  
  func body(content: Content) -> some View {
    content
      .overlay(
        LinearGradient(
          gradient: Gradient(colors: [
            Color.clear,
            Color.surface.opacity(0.3),
            Color.clear
          ]),
          startPoint: .leading,
          endPoint: .trailing
        )
        .rotationEffect(.degrees(30))
        .offset(x: phase * 400 - 200)
        .mask(content)
      )
      .onAppear {
        withAnimation(
          Animation.linear(duration: 1.5)
            .repeatForever(autoreverses: false)
        ) {
          phase = 1
        }
      }
  }
}

extension View {
  func shimmering() -> some View {
    modifier(ShimmeringView())
  }
}
