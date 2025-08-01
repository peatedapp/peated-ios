import SwiftUI
import PeatedCore

struct ProfileView: View {
  @State private var model = ProfileModel()
  @State private var showingLogoutAlert = false
  @State private var selectedTab = 0
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          // Profile header
          profileHeader
          
          // Stats section
          statsSection
            .padding(.horizontal)
            .padding(.vertical, 20)
          
          // Badges section
          if !model.achievements.isEmpty {
            badgesSection
              .padding(.bottom, 20)
          }
          
          // Tab selection
          Picker("Content", selection: $selectedTab) {
            Text("Activity").tag(0)
            Text("Favorites").tag(1)
          }
          .pickerStyle(.segmented)
          .padding(.horizontal)
          .padding(.bottom, 16)
          
          // Tab content
          Group {
            if selectedTab == 0 {
              activitySection
            } else {
              favoritesSection
            }
          }
          .padding(.horizontal)
        }
      }
      .navigationTitle("Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: {
            showingLogoutAlert = true
          }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
              .foregroundColor(.red)
          }
        }
      }
      .alert("Sign Out", isPresented: $showingLogoutAlert) {
        Button("Cancel", role: .cancel) { }
        Button("Sign Out", role: .destructive) {
          Task {
            await model.logout()
          }
        }
      } message: {
        Text("Are you sure you want to sign out?")
      }
    }
    .task {
      await model.loadUser()
    }
  }
  
  private var profileHeader: some View {
    VStack(spacing: 16) {
      // Avatar
      if let pictureUrl = model.user?.pictureUrl, !pictureUrl.isEmpty {
        AsyncImage(url: URL(string: pictureUrl)) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
              ProgressView()
                .tint(.gray)
            )
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
      } else {
        Circle()
          .fill(Color.gray.opacity(0.3))
          .frame(width: 100, height: 100)
          .overlay(
            Text(model.user?.username.prefix(1).uppercased() ?? "?")
              .font(.largeTitle)
              .fontWeight(.medium)
              .foregroundColor(.gray)
          )
      }
      
      // Username and email
      VStack(spacing: 4) {
        Text("@\(model.user?.username ?? "Loading...")")
          .font(.title2)
          .fontWeight(.semibold)
        
        Text(model.user?.email ?? "")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      
      // Role badges
      HStack(spacing: 8) {
        if let user = model.user {
          if user.admin {
            HStack(spacing: 4) {
              Image(systemName: "shield.fill")
                .font(.caption2)
              Text("Admin")
                .font(.caption)
                .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)
          } else if user.mod {
            HStack(spacing: 4) {
              Image(systemName: "star.fill")
                .font(.caption2)
              Text("Moderator")
                .font(.caption)
                .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
          }
        }
      }
    }
    .padding(.top, 20)
    .padding(.horizontal)
  }
  
  private var statsSection: some View {
    HStack(spacing: 0) {
      StatView(title: "Tastings", value: model.user?.tastingsCount ?? 0)
      Divider()
        .frame(height: 40)
      StatView(title: "Bottles", value: model.user?.bottlesCount ?? 0)
      Divider()
        .frame(height: 40)
      StatView(title: "Collected", value: model.user?.collectedCount ?? 0)
      Divider()
        .frame(height: 40)
      StatView(title: "Contributions", value: model.user?.contributionsCount ?? 0)
    }
    .padding(.vertical, 16)
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }
  
  private var badgesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Achievements")
        .font(.headline)
        .padding(.horizontal)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(model.achievements) { achievement in
            VStack(spacing: 6) {
              // Badge icon with proper styling
              ZStack {
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.orange.opacity(0.15))
                  .frame(width: 80, height: 80)
                
                VStack(spacing: 2) {
                  Image(systemName: achievementIcon(for: achievement.name))
                    .font(.title)
                    .foregroundColor(.orange)
                  
                  if achievement.level > 0 {
                    Text("\(achievement.level)")
                      .font(.caption2)
                      .fontWeight(.bold)
                      .foregroundColor(.orange)
                  }
                }
              }
              
              Text(achievement.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .frame(width: 80)
                .lineLimit(2)
            }
          }
        }
        .padding(.horizontal)
      }
    }
  }
  
  private func achievementIcon(for name: String) -> String {
    switch name.lowercased() {
    case let n where n.contains("malt"):
      return "leaf.fill"
    case let n where n.contains("bourbon"):
      return "flame.fill"
    case let n where n.contains("explorer"):
      return "map.fill"
    default:
      return "medal.fill"
    }
  }
  
  private var activitySection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Recent Activity")
        .font(.headline)
      
      Text("No recent activity")
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }
  }
  
  private var favoritesSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Favorites")
        .font(.headline)
      
      Text("No favorites yet")
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }
  }
}

struct StatView: View {
  let title: String
  let value: Int
  
  var body: some View {
    VStack(spacing: 4) {
      Text(formatNumber(value))
        .font(.title2)
        .fontWeight(.semibold)
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
  
  private func formatNumber(_ number: Int) -> String {
    if number >= 1_000_000 {
      let millions = Double(number) / 1_000_000
      return String(format: "%.1fM", millions)
    } else if number >= 10_000 {
      let thousands = Double(number) / 1_000
      return String(format: "%.0fk", thousands)
    } else if number >= 1_000 {
      let thousands = Double(number) / 1_000
      return String(format: "%.1fk", thousands)
    } else {
      return "\(number)"
    }
  }
}

#Preview {
  ProfileView()
}