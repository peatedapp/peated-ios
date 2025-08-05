import SwiftUI
import PeatedCore

struct TastingDetailView: View {
  let tastingId: String
  let onNavigateToProfile: ((String) -> Void)?
  
  @State private var model: TastingDetailModel
  @State private var commentText = ""
  @State private var showingToastList = false
  @State private var showingDeleteAlert = false
  @FocusState private var isCommentFieldFocused: Bool
  @Environment(\.dismiss) private var dismiss
  
  init(tastingId: String, onNavigateToProfile: ((String) -> Void)? = nil) {
    self.tastingId = tastingId
    self.onNavigateToProfile = onNavigateToProfile
    self._model = State(initialValue: TastingDetailModel(tastingId: tastingId))
  }
  
  var body: some View {
    Group {
      switch model.state {
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
              .foregroundColor(.peatedTextPrimary)
          }
        }
      }
    }
    .task {
      await model.loadTasting()
    }
    .sheet(isPresented: $showingToastList) {
      if let tasting = model.tasting {
        ToastListView(tasting: tasting)
      }
    }
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
  }
  
  // MARK: - Loading View
  
  @ViewBuilder
  private var loadingView: some View {
    ScrollView {
      VStack(spacing: 16) {
        // Tasting card skeleton
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.peatedSurfaceLight)
          .frame(height: 300)
          .shimmer()
        
        // Comment skeletons
        ForEach(0..<3, id: \.self) { _ in
          HStack(alignment: .top, spacing: 12) {
            Circle()
              .fill(Color.peatedSurfaceLight)
              .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 8) {
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.peatedSurfaceLight)
                .frame(width: 120, height: 14)
              
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.peatedSurfaceLight)
                .frame(height: 40)
            }
          }
          .shimmer()
        }
      }
      .padding()
    }
    .background(Color.peatedBackground)
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
              // Already on tasting detail, do nothing
            }
          )
          
          Divider()
            .padding(.vertical, 16)
          
          // Toasts section
          if tasting.toastCount > 0 {
            toastsSection(tasting)
              .padding(.horizontal)
            
            Divider()
              .padding(.vertical, 16)
          }
          
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
    .background(Color.peatedBackground)
  }
  
  // MARK: - Toasts Section
  
  @ViewBuilder
  private func toastsSection(_ tasting: TastingDetail) -> some View {
    Button {
      showingToastList = true
    } label: {
      HStack {
        Text("Toasts")
          .font(.peatedHeadline)
          .foregroundColor(.peatedTextPrimary)
        
        Text("(\(tasting.toastCount))")
          .font(.peatedSubheadline)
          .foregroundColor(.peatedTextSecondary)
        
        Spacer()
        
        // Show preview of toasters
        if !tasting.toasts.isEmpty {
          HStack(spacing: -8) {
            ForEach(tasting.toasts.prefix(5)) { toast in
              if let url = toast.userAvatarUrl, let avatarUrl = URL(string: url) {
                AsyncImage(url: avatarUrl) { image in
                  image
                    .resizable()
                    .scaledToFill()
                } placeholder: {
                  Circle()
                    .fill(Color.peatedSurfaceLight)
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
                .overlay(
                  Circle()
                    .stroke(Color.peatedBackground, lineWidth: 2)
                )
              }
            }
            
            if tasting.toastCount > 5 {
              Text("+\(tasting.toastCount - 5)")
                .font(.peatedCaption)
                .foregroundColor(.peatedTextSecondary)
                .padding(.leading, 4)
            }
          }
          
          Image(systemName: "chevron.right")
            .font(.peatedCaption)
            .foregroundColor(.peatedTextSecondary)
        }
      }
    }
    .buttonStyle(.plain)
  }
  
  // MARK: - Comments Section
  
  @ViewBuilder
  private func commentsSection(_ tasting: TastingDetail) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Comments")
          .font(.peatedHeadline)
          .foregroundColor(.peatedTextPrimary)
        
        if case .loaded(let comments) = model.commentState, !comments.isEmpty {
          Text("(\(comments.count))")
            .font(.peatedSubheadline)
            .foregroundColor(.peatedTextSecondary)
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
              .fill(Color.peatedSurfaceLight)
              .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 8) {
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.peatedSurfaceLight)
                .frame(width: 120, height: 14)
              
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.peatedSurfaceLight)
                .frame(height: 40)
            }
          }
          .shimmer()
        }
        
      case .loaded(let comments):
        if comments.isEmpty {
          Text("No comments yet. Be the first!")
            .font(.peatedBody)
            .foregroundColor(.peatedTextSecondary)
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
            .foregroundColor(.orange)
          
          Text("Failed to load comments")
            .font(.peatedSubheadline)
            .foregroundColor(.peatedTextPrimary)
          
          Button {
            Task {
              await model.loadComments()
            }
          } label: {
            Text("Try Again")
              .font(.peatedCaption)
              .foregroundColor(.peatedGold)
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
      HStack {
        TextField("Add a comment...", text: $commentText, axis: .vertical)
          .font(.peatedBody)
          .foregroundColor(.peatedTextPrimary)
          .tint(.peatedGold)
          .lineLimit(1...4)
          .focused($isCommentFieldFocused)
        
        if !commentText.isEmpty {
          Button {
            Task {
              await postComment()
            }
          } label: {
            Image(systemName: "arrow.up.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.peatedGold)
          }
          .disabled(model.isPostingComment)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(Color.peatedSurfaceLight)
      .cornerRadius(20)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(Color.peatedSurface)
  }
  
  // MARK: - Error View
  
  @ViewBuilder
  private func errorView(_ message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 50))
        .foregroundColor(.orange)
      
      Text("Unable to load tasting")
        .font(.peatedTitle3)
        .fontWeight(.semibold)
        .foregroundColor(.peatedTextPrimary)
      
      Text(message)
        .font(.peatedBody)
        .foregroundColor(.peatedTextSecondary)
        .multilineTextAlignment(.center)
      
      Button {
        Task {
          await model.loadTasting()
        }
      } label: {
        Text("Try Again")
          .font(.peatedBody)
          .fontWeight(.medium)
          .foregroundColor(.peatedBackground)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .background(Color.peatedGold)
          .cornerRadius(20)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.peatedBackground)
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
        if let imageUrl = tasting.bottleImageUrl, let url = URL(string: imageUrl) {
          AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            case .failure, .empty:
              Image(systemName: "wineglass")
                .font(.system(size: 24))
                .foregroundColor(.peatedTextMuted)
            @unknown default:
              ProgressView()
            }
          }
          .frame(width: 60, height: 80)
          .background(Color.peatedSurfaceLight)
          .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        
        VStack(alignment: .leading, spacing: 4) {
          Text(tasting.bottleName)
            .font(.peatedHeadline)
            .foregroundColor(.peatedTextPrimary)
          
          HStack(spacing: 4) {
            Text(tasting.bottleBrandName)
              .font(.peatedSubheadline)
              .foregroundColor(.peatedTextSecondary)
            
            if let category = tasting.bottleCategory {
              Text("•")
                .font(.peatedSubheadline)
                .foregroundColor(.peatedTextMuted)
              
              Text(category.capitalized)
                .font(.peatedSubheadline)
                .foregroundColor(.peatedTextSecondary)
            }
          }
          
          // Rating
          HStack(spacing: 4) {
            ForEach(0..<5) { index in
              Image(systemName: index < Int(tasting.rating) ? "star.fill" : "star")
                .font(.system(size: 14))
                .foregroundColor(.peatedGold)
            }
            
            Text(String(format: "%.1f", tasting.rating))
              .font(.peatedBody)
              .fontWeight(.medium)
              .foregroundColor(.peatedTextPrimary)
          }
          .padding(.top, 4)
        }
        
        Spacer()
      }
      
      // Notes (full, not truncated)
      if let notes = tasting.notes, !notes.isEmpty {
        Text(notes)
          .font(.peatedBody)
          .foregroundColor(.peatedTextPrimary)
          .fixedSize(horizontal: false, vertical: true)
      }
      
      // Tags
      if !tasting.tags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(tasting.tags, id: \.self) { tag in
              Text("#\(tag)")
                .font(.peatedCaption)
                .foregroundColor(.peatedGold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.peatedGold.opacity(0.1))
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
          if let avatarUrl = tasting.userAvatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
              image
                .resizable()
                .scaledToFill()
            } placeholder: {
              Circle()
                .fill(Color.peatedSurfaceLight)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
          }
          
          VStack(alignment: .leading, spacing: 2) {
            Text(tasting.authorDisplayName)
              .font(.peatedSubheadline)
              .fontWeight(.medium)
              .foregroundColor(.peatedTextPrimary)
            
            Text("@\(tasting.username) • \(tasting.timeAgo)")
              .font(.peatedCaption)
              .foregroundColor(.peatedTextSecondary)
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
          .foregroundColor(tasting.hasToasted ? .peatedGold : .peatedTextSecondary)
        }
      }
    }
    .padding()
    .background(Color.peatedSurface)
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
          if let avatarUrl = comment.userAvatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
              image
                .resizable()
                .scaledToFill()
            } placeholder: {
              Circle()
                .fill(Color.peatedSurfaceLight)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
          } else {
            Circle()
              .fill(Color.peatedSurfaceLight)
              .overlay(
                Image(systemName: "person.fill")
                  .font(.system(size: 16))
                  .foregroundColor(.peatedTextMuted)
              )
              .frame(width: 32, height: 32)
          }
        }
        
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(comment.authorDisplayName)
              .font(.peatedSubheadline)
              .fontWeight(.semibold)
              .foregroundColor(.peatedTextPrimary)
            
            if isOP {
              Text("OP")
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.peatedGold.opacity(0.2))
                .foregroundColor(.peatedGold)
                .cornerRadius(4)
            }
            
            Text("•")
              .font(.peatedCaption)
              .foregroundColor(.peatedTextMuted)
            
            Text(comment.timeAgo)
              .font(.peatedCaption)
              .foregroundColor(.peatedTextSecondary)
          }
          
          Text(comment.text)
            .font(.peatedBody)
            .foregroundColor(.peatedTextPrimary)
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
              .foregroundColor(.peatedTextSecondary)
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
  let tasting: TastingDetail
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      List(tasting.toasts) { toast in
        HStack {
          if let avatarUrl = toast.userAvatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
              image
                .resizable()
                .scaledToFill()
            } placeholder: {
              Circle()
                .fill(Color.peatedSurfaceLight)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
          }
          
          VStack(alignment: .leading, spacing: 2) {
            Text(toast.userDisplayName ?? toast.username)
              .font(.peatedBody)
              .fontWeight(.medium)
              .foregroundColor(.peatedTextPrimary)
            
            Text("@\(toast.username)")
              .font(.peatedCaption)
              .foregroundColor(.peatedTextSecondary)
          }
          
          Spacer()
          
          // TODO: Add follow button
        }
        .padding(.vertical, 4)
      }
      .listStyle(.plain)
      .navigationTitle("Toasts")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .foregroundColor(.peatedGold)
        }
      }
    }
  }
}

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
            Color.white.opacity(0.3),
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