import SwiftUI
import PeatedCore

struct BottleDetailView: View {
  let bottleId: String
  let bottleName: String?
  
  @State private var model: BottleDetailModel
  @State private var showingCreateTasting = false
  @State private var showingShareSheet = false
  
  init(bottleId: String, bottleName: String? = nil) {
    self.bottleId = bottleId
    self.bottleName = bottleName
    self._model = State(initialValue: BottleDetailModel(bottleId: bottleId))
  }
  
  var body: some View {
    Group {
      switch model.state {
      case .loading:
        loadingView
      case .loaded(let bottle):
        loadedView(bottle)
      case .error(let message):
        errorView(message)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button(action: { showingShareSheet = true }) {
            Label("Share", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .task {
      await model.loadBottle()
    }
    .sheet(isPresented: $showingCreateTasting) {
      if let bottle = model.bottle {
        // TODO: Pass preselected bottle to CreateTastingFlow
        CreateTastingFlow(onSuccess: {
          // Refresh to show new tasting
          Task {
            await model.refresh()
          }
        })
      }
    }
  }
  
  // MARK: - Loading View
  @ViewBuilder
  private var loadingView: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Image placeholder
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.3))
          .frame(height: 300)
          .padding(.horizontal)
        
        // Content placeholders
        VStack(alignment: .leading, spacing: 12) {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 24)
            .frame(maxWidth: 200)
          
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 20)
            .frame(maxWidth: 150)
        }
        .padding(.horizontal)
      }
      .redacted(reason: .placeholder)
    }
  }
  
  // MARK: - Loaded View
  @ViewBuilder
  private func loadedView(_ bottle: Bottle) -> some View {
    ScrollView {
      VStack(spacing: 0) {
        // Hero section
        heroSection(bottle)
        
        // Action buttons
        actionButtons(bottle)
          .padding(.horizontal)
          .padding(.vertical, 20)
        
        Divider()
          .padding(.vertical, 8)
        
        // Content sections
        VStack(spacing: 24) {
          // About section - placeholder for now
          aboutSection(bottle)
          
          // Recent activity
          if !model.recentTastings.isEmpty {
            recentActivitySection
          }
          
          // Similar bottles
          if !model.similarBottles.isEmpty {
            similarBottlesSection
          }
        }
        .padding(.vertical, 16)
      }
    }
    .refreshable {
      await model.refresh()
    }
  }
  
  // MARK: - Hero Section
  @ViewBuilder
  private func heroSection(_ bottle: Bottle) -> some View {
    VStack(spacing: 16) {
      // Bottle image
      if let imageUrl = bottle.imageUrl, let url = URL(string: imageUrl) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
          case .failure, .empty:
            Image(systemName: "wineglass")
              .font(.system(size: 60))
              .foregroundColor(.secondary)
          @unknown default:
            ProgressView()
              .scaleEffect(0.5)
          }
        }
        .frame(height: 300)
      } else {
        Image(systemName: "wineglass")
          .font(.system(size: 60))
          .foregroundColor(.secondary)
          .frame(height: 300)
      }
      
      // Bottle info
      VStack(spacing: 12) {
        Text(bottle.fullName)
          .font(.title)
          .fontWeight(.bold)
          .multilineTextAlignment(.center)
        
        Button(action: {
          // TODO: Navigate to brand/entity detail
        }) {
          Text(bottle.brandName)
            .font(.body)
            .foregroundColor(.peatedGold)
        }
        
        // Rating
        if bottle.totalRatings > 0 {
          HStack(spacing: 8) {
            HStack(spacing: 4) {
              ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= Int(bottle.avgRating.rounded()) ? "star.fill" : "star")
                  .font(.system(size: 16))
                  .foregroundColor(.yellow)
              }
            }
            
            Text(String(format: "%.1f", bottle.avgRating))
              .font(.title3)
              .fontWeight(.semibold)
            
            Text("(\(bottle.totalRatings) ratings)")
              .font(.body)
              .foregroundColor(.secondary)
          }
        }
        
        // Metadata
        HStack(spacing: 12) {
          if let category = bottle.category {
            Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
              .font(.caption)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color(.secondarySystemBackground))
              .cornerRadius(12)
          }
          
          if let abv = bottle.abv {
            Text("\(abv, specifier: "%.1f")% ABV")
              .font(.caption)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color(.secondarySystemBackground))
              .cornerRadius(12)
          }
          
          if let age = bottle.statedAge {
            Text("\(age) Year")
              .font(.caption)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color(.secondarySystemBackground))
              .cornerRadius(12)
          }
        }
      }
      .padding(.horizontal)
    }
  }
  
  // MARK: - Action Buttons
  @ViewBuilder
  private func actionButtons(_ bottle: Bottle) -> some View {
    VStack(spacing: 12) {
      // Primary CTA
      Button(action: { showingCreateTasting = true }) {
        Label("Record Tasting", systemImage: "plus.circle.fill")
          .font(.body)
          .fontWeight(.semibold)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(Color.peatedGold)
          .cornerRadius(12)
      }
    }
  }
  
  // MARK: - About Section
  @ViewBuilder
  private func aboutSection(_ bottle: Bottle) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Details")
        .font(.headline)
        .padding(.horizontal)
      
      VStack(alignment: .leading, spacing: 8) {
        if bottle.caskStrength {
          Label("Cask Strength", systemImage: "checkmark.circle.fill")
            .font(.body)
            .foregroundColor(.green)
        }
        
        if bottle.singleCask {
          Label("Single Cask", systemImage: "checkmark.circle.fill")
            .font(.body)
            .foregroundColor(.green)
        }
        
        if let category = bottle.category {
          HStack {
            Text("Category:")
              .font(.body)
              .foregroundColor(.secondary)
            Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
              .font(.body)
          }
        }
        
        if let abv = bottle.abv {
          HStack {
            Text("ABV:")
              .font(.body)
              .foregroundColor(.secondary)
            Text("\(abv, specifier: "%.1f")%")
              .font(.body)
          }
        }
      }
      .padding()
      .background(Color(.secondarySystemBackground))
      .cornerRadius(12)
      .padding(.horizontal)
    }
  }
  
  // MARK: - Recent Activity Section
  @ViewBuilder
  private var recentActivitySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Recent Activity")
          .font(.headline)
        
        Spacer()
      }
      .padding(.horizontal)
      
      VStack(spacing: 0) {
        ForEach(model.recentTastings.prefix(3)) { tasting in
          VStack(spacing: 0) {
            TastingFeedCard(
              tasting: tasting,
              showBottle: false,  // Hide bottle info since we're on the bottle page
              onToast: {
                // TODO: Implement toast functionality
              },
              onComment: {
                // TODO: Navigate to tasting detail
              },
              onUserTap: {
                // TODO: Navigate to user profile
              },
              onBottleTap: {
                // No-op since we're already on the bottle page
              }
            )
            .padding(.horizontal)
            
            // Add divider between items
            if tasting != model.recentTastings.prefix(3).last {
              Divider()
                .background(Color.gray.opacity(0.2))
            }
          }
        }
      }
    }
  }
  
  // MARK: - Similar Bottles Section
  @ViewBuilder
  private var similarBottlesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Similar Bottles")
        .font(.headline)
        .padding(.horizontal)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(model.similarBottles) { bottle in
            NavigationLink(destination: BottleDetailView(bottleId: bottle.id, bottleName: bottle.fullName)) {
              SimilarBottleCard(bottle: bottle)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
      }
    }
  }
  
  // MARK: - Error View
  @ViewBuilder
  private func errorView(_ message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 50))
        .foregroundColor(.orange)
      
      Text("Unable to load bottle")
        .font(.title3)
        .fontWeight(.semibold)
      
      Text(message)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      
      Button(action: {
        Task {
          await model.loadBottle()
        }
      }) {
        Text("Try Again")
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .background(Color.peatedGold)
          .cornerRadius(20)
      }
    }
    .padding()
  }
}

// MARK: - Supporting Views
struct SimilarBottleCard: View {
  let bottle: Bottle
  
  var body: some View {
    VStack(spacing: 8) {
      // Bottle image
      if let imageUrl = bottle.imageUrl, let url = URL(string: imageUrl) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
          case .failure, .empty:
            Image(systemName: "wineglass")
              .font(.system(size: 24))
              .foregroundColor(.secondary)
          @unknown default:
            ProgressView()
              .scaleEffect(0.5)
          }
        }
        .frame(width: 80, height: 120)
      } else {
        Image(systemName: "wineglass")
          .font(.system(size: 24))
          .foregroundColor(.secondary)
          .frame(width: 80, height: 120)
      }
      
      VStack(spacing: 4) {
        Text(bottle.name)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.primary)
          .lineLimit(2)
          .multilineTextAlignment(.center)
        
        if bottle.totalRatings > 0 {
          HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
              Image(systemName: star <= Int(bottle.avgRating.rounded()) ? "star.fill" : "star")
                .font(.system(size: 10))
                .foregroundColor(.yellow)
            }
          }
          Text(String(format: "%.1f", bottle.avgRating))
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
    }
    .frame(width: 120)
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
  }
}