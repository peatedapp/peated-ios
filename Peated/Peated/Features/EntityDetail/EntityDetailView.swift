import SwiftUI
import PeatedCore

struct EntityDetailView: View {
  @State private var model: EntityDetailModel
  @State private var selectedTab = 0
  @State private var isDescriptionExpanded = false
  @Environment(\.dismiss) private var dismiss
  let entityName: String?
  
  init(entityId: String, entityName: String? = nil) {
    _model = State(initialValue: EntityDetailModel(entityId: entityId))
    self.entityName = entityName
  }
  
  var body: some View {
    Group {
      switch model.state {
      case .loading:
        LoadingView()
      case .loaded(let entity):
        ScrollView {
          VStack(spacing: 0) {
            // Hero Section
            heroSection(entity: entity)
            
            // Stats section
            statsSection(entity: entity)
              .padding(.horizontal)
              .padding(.vertical, 20)
            
            // About section (if description exists)
            if let description = entity.description, !description.isEmpty {
              aboutSection(entity: entity)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            
            // Tab selection
            Picker("Content", selection: $selectedTab) {
              Text("Activity").tag(0)
              Text("Bottles").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Tab content
            Group {
              if selectedTab == 0 {
                activitySection()
              } else {
                bottlesSection()
                  .padding(.horizontal)
              }
            }
          }
        }
        .background(Color.background)
      case .error(let error):
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 48))
            .foregroundColor(.warning)
          Text("Failed to load entity")
            .font(.title3)
            .fontWeight(.semibold)
          Text(error.localizedDescription)
            .font(.footnote)
            .foregroundColor(.textSecondary)
            .multilineTextAlignment(.center)
          Button("Retry") {
            Task {
              await model.retry()
            }
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await model.loadEntity()
    }
  }
  
  // MARK: - Hero Section
  
  @ViewBuilder
  private func heroSection(entity: Entity) -> some View {
    VStack(spacing: 16) {
      // Entity Image or Placeholder
      ZStack {
        Circle()
          .fill(Color.surface)
          .frame(width: 100, height: 100)
        
        if let imageUrl = entity.imageUrl {
          AsyncImage(url: URL(string: imageUrl)) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 100, height: 100)
              .clipShape(Circle())
          } placeholder: {
            ProgressView()
          }
        } else {
          Image(systemName: entity.type == .distillery ? "building.2" : "tag")
            .font(.system(size: 40))
            .foregroundColor(.textSecondary.opacity(0.5))
        }
      }
      
      // Entity Name and Type
      VStack(spacing: 4) {
        Text(entity.name)
          .font(.system(size: 24, weight: .regular, design: .default))
          .foregroundColor(.text)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
          .minimumScaleFactor(0.98)
          .padding(.horizontal)
        
        HStack(spacing: 8) {
          Label(entity.type.displayName, systemImage: entity.type == .distillery ? "building.2" : "tag")
            .font(.system(size: DesignSystem.FontSize.small))
            .foregroundColor(.textSecondary)
          
          if let country = entity.country {
            Text("•")
              .foregroundColor(.textSecondary)
            HStack(spacing: 4) {
              Image(systemName: "location")
                .font(.system(size: 10))
              Text(country)
            }
            .font(.system(size: DesignSystem.FontSize.small))
            .foregroundColor(.textSecondary)
          }
        }
      }
    }
    .padding(.top, 20)
  }
  
  // MARK: - Stats Section
  
  @ViewBuilder
  private func statsSection(entity: Entity) -> some View {
    HStack(spacing: 0) {
      // Bottles stat
      VStack(spacing: 8) {
        Text("\(entity.totalBottles)")
          .font(.title2)
          .fontWeight(.bold)
        Text("Bottles")
          .font(.caption)
          .foregroundColor(.textSecondary)
      }
      .frame(maxWidth: .infinity)
      
      Divider()
        .frame(height: 40)
        .background(Color.border.opacity(0.3))
      
      // Tastings stat
      VStack(spacing: 8) {
        Text("\(entity.totalTastings)")
          .font(.title2)
          .fontWeight(.bold)
        Text("Tastings")
          .font(.caption)
          .foregroundColor(.textSecondary)
      }
      .frame(maxWidth: .infinity)
      
      if let region = entity.region {
        Divider()
          .frame(height: 40)
          .background(Color.border.opacity(0.3))
        
        // Region
        VStack(spacing: 8) {
          Text(region)
            .font(.subheadline)
            .fontWeight(.semibold)
            .lineLimit(1)
          Text("Region")
            .font(.caption)
            .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
      }
    }
    .padding(.vertical, 12)
    .background(Color.surface.opacity(0.5))
    .cornerRadius(DesignSystem.CornerRadius.medium)
  }
  
  // MARK: - About Section
  
  @ViewBuilder
  private func aboutSection(entity: Entity) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("ABOUT")
        .font(.system(size: DesignSystem.FontSize.small))
        .fontWeight(.semibold)
        .foregroundColor(.textSecondary)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(entity.description ?? "")
          .font(.system(size: DesignSystem.FontSize.body))
          .foregroundColor(.text)
          .lineLimit(isDescriptionExpanded ? nil : 3)
          .fixedSize(horizontal: false, vertical: true)
        
        // Only show button if text is long enough to be truncated
        if let description = entity.description, description.count > 150 {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
              isDescriptionExpanded.toggle()
            }
          }) {
            Text(isDescriptionExpanded ? "Show less" : "Read more")
              .font(.system(size: DesignSystem.FontSize.small))
              .fontWeight(.medium)
              .foregroundColor(.brand)
          }
          .padding(.top, 2)
        }
      }
    }
  }
  
  // MARK: - Activity Section
  
  @ViewBuilder
  private func activitySection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      if model.isLoadingTastings && model.recentTastings.isEmpty {
        // Loading state
        VStack(spacing: 0) {
          ForEach(0..<3) { index in
            VStack(spacing: 0) {
              SkeletonTastingCard()
              
              if index < 2 {
                Divider()
                  .background(Color.border.opacity(0.2))
              }
            }
          }
        }
      } else if model.recentTastings.isEmpty {
        // Empty state
        Text("No recent activity")
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 40)
      } else {
        // Show tastings using unified feed card design
        ActivityList(
          tastings: model.recentTastings,
          showBottle: true,
          onToast: { _ in /* TODO: Implement toasting */ },
          onComment: { _ in /* TODO: Implement comments */ },
          onUserTap: { _ in /* TODO: Navigate to user profile */ },
          onBottleTap: { _ in /* TODO: Navigate to bottle */ }
        )
      }
    }
  }
  
  // MARK: - Bottles Section
  
  @ViewBuilder
  private func bottlesSection() -> some View {
    if model.isLoadingBottles && model.bottles.isEmpty {
      // Loading state
      VStack(spacing: 12) {
        ForEach(0..<3) { _ in
          HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.border.opacity(0.3))
              .frame(width: 60, height: 80)
            
            VStack(alignment: .leading, spacing: 4) {
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.border.opacity(0.3))
                .frame(width: 150, height: 16)
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.border.opacity(0.3))
                .frame(width: 100, height: 12)
            }
            
            Spacer()
          }
          .shimmer()
        }
      }
      .padding(.vertical)
    } else if model.bottles.isEmpty {
      // Empty state
      Text("No bottles found")
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    } else {
      // Bottles grid
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        ForEach(model.bottles) { bottle in
          NavigationLink(destination: BottleDetailView(bottleId: bottle.id)) {
            VStack(alignment: .leading, spacing: 8) {
              // Bottle Image
              ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                  .fill(Color.border.opacity(0.1))
                  .aspectRatio(0.7, contentMode: .fit)
                
                if let imageUrl = bottle.imageUrl {
                  AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                  } placeholder: {
                    ProgressView()
                  }
                } else {
                  Image(systemName: "wineglass")
                    .font(.system(size: 30))
                    .foregroundColor(.textSecondary.opacity(0.3))
                }
              }
              
              // Bottle Info
              VStack(alignment: .leading, spacing: 2) {
                Text(bottle.name)
                  .font(.system(size: DesignSystem.FontSize.small, weight: .semibold))
                  .foregroundColor(.primary)
                  .lineLimit(2)
                  .multilineTextAlignment(.leading)
                
                if let category = bottle.category {
                  Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: DesignSystem.FontSize.caption))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                }
                
                if bottle.totalRatings > 0 {
                  HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                      .font(.system(size: 10))
                      .foregroundColor(.brand)
                    
                    Text(String(format: "%.1f", bottle.avgRating))
                      .font(.system(size: DesignSystem.FontSize.caption))
                      .foregroundColor(.text)
                    
                    Text("(\(bottle.totalRatings))")
                      .font(.system(size: DesignSystem.FontSize.caption))
                      .foregroundColor(.textSecondary)
                  }
                }
              }
            }
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.vertical)
    }
  }
}
