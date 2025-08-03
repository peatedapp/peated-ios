import SwiftUI
import PeatedCore

/// Displays network status indicator when offline or in limited connectivity
struct OfflineIndicator: View {
  @State private var networkMonitor = NetworkMonitor.shared
  @State private var queueManager = OfflineQueueManager.shared
  
  var body: some View {
    VStack(spacing: 0) {
      // Main offline indicator
      if !networkMonitor.isConnected {
        offlineBar
      }
      
      // Sync status indicator
      if networkMonitor.isConnected && queueManager.isSyncing {
        syncingBar
      }
    }
    .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    .animation(.easeInOut(duration: 0.3), value: queueManager.isSyncing)
  }
  
  // MARK: - Offline Bar
  
  @ViewBuilder
  private var offlineBar: some View {
    HStack(spacing: 8) {
      Image(systemName: "wifi.slash")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white)
      
      Text("You're offline")
        .font(.peatedCaption)
        .fontWeight(.medium)
        .foregroundColor(.white)
      
      if queueManager.pendingCount > 0 {
        Text("•")
          .foregroundColor(.white.opacity(0.6))
        
        Text("\(queueManager.pendingCount) pending")
          .font(.peatedCaption)
          .foregroundColor(.white.opacity(0.8))
      }
      
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color.red)
    .transition(.move(edge: .top).combined(with: .opacity))
  }
  
  // MARK: - Syncing Bar
  
  @ViewBuilder
  private var syncingBar: some View {
    HStack(spacing: 8) {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .white))
        .scaleEffect(0.7)
      
      Text("Syncing \(queueManager.pendingCount) changes...")
        .font(.peatedCaption)
        .fontWeight(.medium)
        .foregroundColor(.white)
      
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color.blue)
    .transition(.move(edge: .top).combined(with: .opacity))
  }
}

/// More detailed offline status view for settings or dedicated screen
struct OfflineStatusView: View {
  @State private var networkMonitor = NetworkMonitor.shared
  @State private var queueManager = OfflineQueueManager.shared
  
  var body: some View {
    VStack(spacing: 24) {
      // Network Status Card
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
            .font(.system(size: 20))
            .foregroundColor(networkMonitor.isConnected ? .green : .red)
          
          Text("Network Status")
            .font(.peatedHeadline)
            .foregroundColor(.peatedTextPrimary)
          
          Spacer()
        }
        
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Connection:")
              .font(.peatedCaption)
              .foregroundColor(.peatedTextSecondary)
            
            Text(networkMonitor.isConnected ? "Online" : "Offline")
              .font(.peatedCaption)
              .fontWeight(.medium)
              .foregroundColor(networkMonitor.isConnected ? .green : .red)
          }
          
          if networkMonitor.isConnected {
            HStack {
              Text("Type:")
                .font(.peatedCaption)
                .foregroundColor(.peatedTextSecondary)
              
              Text(networkMonitor.connectionType.displayName)
                .font(.peatedCaption)
                .fontWeight(.medium)
                .foregroundColor(.peatedTextPrimary)
            }
            
            if networkMonitor.isExpensive {
              HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                  .font(.system(size: 12))
                  .foregroundColor(.orange)
                
                Text("Expensive connection")
                  .font(.peatedCaption)
                  .foregroundColor(.orange)
              }
            }
            
            if networkMonitor.isConstrained {
              HStack {
                Image(systemName: "tortoise.fill")
                  .font(.system(size: 12))
                  .foregroundColor(.orange)
                
                Text("Low data mode")
                  .font(.peatedCaption)
                  .foregroundColor(.orange)
              }
            }
          }
        }
      }
      .padding()
      .background(Color.peatedSurfaceLight)
      .cornerRadius(12)
      
      // Offline Queue Status
      if queueManager.pendingCount > 0 {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Image(systemName: "arrow.up.arrow.down.circle")
              .font(.system(size: 20))
              .foregroundColor(.blue)
            
            Text("Pending Sync")
              .font(.peatedHeadline)
              .foregroundColor(.peatedTextPrimary)
            
            Spacer()
            
            if queueManager.isSyncing {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(0.8)
            }
          }
          
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Pending:")
                .font(.peatedCaption)
                .foregroundColor(.peatedTextSecondary)
              
              Text("\(queueManager.pendingCount) operations")
                .font(.peatedCaption)
                .fontWeight(.medium)
                .foregroundColor(.peatedTextPrimary)
            }
            
            if queueManager.failedCount > 0 {
              HStack {
                Text("Failed:")
                  .font(.peatedCaption)
                  .foregroundColor(.peatedTextSecondary)
                
                Text("\(queueManager.failedCount) operations")
                  .font(.peatedCaption)
                  .fontWeight(.medium)
                  .foregroundColor(.red)
              }
            }
            
            // Operation breakdown
            if !queueManager.operationsSummary.isEmpty {
              Divider()
                .padding(.vertical, 4)
              
              ForEach(Array(queueManager.operationsSummary), id: \.key) { type, count in
                HStack {
                  Text(type.description)
                    .font(.peatedCaption)
                    .foregroundColor(.peatedTextSecondary)
                  
                  Spacer()
                  
                  Text("\(count)")
                    .font(.peatedCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.peatedTextPrimary)
                }
              }
            }
          }
          
          if queueManager.failedCount > 0 && networkMonitor.isConnected {
            Button(action: {
              Task {
                await queueManager.retryFailedOperations()
              }
            }) {
              HStack {
                Image(systemName: "arrow.clockwise")
                  .font(.system(size: 14))
                
                Text("Retry Failed Operations")
                  .font(.peatedCaption)
                  .fontWeight(.medium)
              }
              .foregroundColor(.blue)
            }
            .padding(.top, 8)
          }
        }
        .padding()
        .background(Color.peatedSurfaceLight)
        .cornerRadius(12)
      }
      
      // Network Preferences
      VStack(alignment: .leading, spacing: 12) {
        Text("Network Preferences")
          .font(.peatedHeadline)
          .foregroundColor(.peatedTextPrimary)
          .padding(.horizontal)
        
        Toggle("Load images on cellular", isOn: Binding(
          get: { UserDefaults.standard.bool(forKey: UserDefaults.NetworkKeys.loadImagesOnCellular) },
          set: { UserDefaults.standard.set($0, forKey: UserDefaults.NetworkKeys.loadImagesOnCellular) }
        ))
        .tint(.peatedGold)
        .padding(.horizontal)
        
        Toggle("Sync on cellular", isOn: Binding(
          get: { UserDefaults.standard.bool(forKey: UserDefaults.NetworkKeys.syncOnCellular) },
          set: { UserDefaults.standard.set($0, forKey: UserDefaults.NetworkKeys.syncOnCellular) }
        ))
        .tint(.peatedGold)
        .padding(.horizontal)
      }
      .padding(.vertical)
      .background(Color.peatedSurfaceLight)
      .cornerRadius(12)
      
      Spacer()
    }
    .padding()
  }
}

// MARK: - Previews

#if DEBUG
struct OfflineIndicator_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      OfflineIndicator()
      
      Spacer()
    }
    .background(Color.peatedBackground)
    
    OfflineStatusView()
      .background(Color.peatedBackground)
  }
}
#endif