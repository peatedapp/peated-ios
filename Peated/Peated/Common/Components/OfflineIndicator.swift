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
        .foregroundColor(.onStatus)
      
      VStack(alignment: .leading, spacing: 0) {
        Text("You're offline")
          .font(.peatedCaption)
          .fontWeight(.semibold)
          .foregroundColor(.onStatus)
        Text("Changes will sync automatically when you're back online.")
          .font(.peatedCaption)
          .foregroundColor(.onStatus.opacity(0.9))
      }
      
      if queueManager.pendingCount > 0 {
        Spacer(minLength: 8)
        Text("\(queueManager.pendingCount) pending")
          .font(.peatedCaption)
          .fontWeight(.medium)
          .foregroundColor(.onStatus)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color.onStatus.opacity(0.18))
          .cornerRadius(6)
      }
      
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color.danger)
    .transition(.move(edge: .top).combined(with: .opacity))
  }
  
  // MARK: - Syncing Bar
  
  @ViewBuilder
  private var syncingBar: some View {
    HStack(spacing: 8) {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .onStatus))
        .scaleEffect(0.7)
      
      Text("Back online — syncing \(queueManager.pendingCount) changes…")
        .font(.peatedCaption)
        .fontWeight(.medium)
        .foregroundColor(.onStatus)
      
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color.info)
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
            .foregroundColor(networkMonitor.isConnected ? .success : .danger)
          
          Text("Network Status")
            .font(.peatedHeadline)
            .foregroundColor(.text)
          
          Spacer()
        }
        
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Connection:")
              .font(.peatedCaption)
              .foregroundColor(.textSecondary)
            
            Text(networkMonitor.isConnected ? "Online" : "Offline")
              .font(.peatedCaption)
              .fontWeight(.medium)
              .foregroundColor(networkMonitor.isConnected ? .success : .danger)
          }
          
          if networkMonitor.isConnected {
            HStack {
              Text("Type:")
                .font(.peatedCaption)
                .foregroundColor(.textSecondary)
              
              Text(networkMonitor.connectionType.displayName)
                .font(.peatedCaption)
                .fontWeight(.medium)
                .foregroundColor(.text)
            }
            
            if networkMonitor.isExpensive {
              HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                  .font(.system(size: 12))
                  .foregroundColor(.warning)
                
                Text("Expensive connection")
                  .font(.peatedCaption)
                  .foregroundColor(.warning)
              }
            }
            
            if networkMonitor.isConstrained {
              HStack {
                Image(systemName: "tortoise.fill")
                  .font(.system(size: 12))
                  .foregroundColor(.warning)
                
                Text("Low data mode")
                  .font(.peatedCaption)
                  .foregroundColor(.warning)
              }
            }
          }
        }
      }
      .padding()
      .background(Color.surface)
      .cornerRadius(12)
      
      // Offline Queue Status
      if queueManager.pendingCount > 0 {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
                Image(systemName: "arrow.up.arrow.down.circle")
                  .font(.system(size: 20))
                  .foregroundColor(.info)
            
            Text("Pending Sync")
              .font(.peatedHeadline)
              .foregroundColor(.text)
            
            Spacer()
            
            if queueManager.isSyncing {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .info))
                .scaleEffect(0.8)
            }
          }
          
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Pending:")
                .font(.peatedCaption)
                .foregroundColor(.textSecondary)
              
              Text("\(queueManager.pendingCount) operations")
                .font(.peatedCaption)
                .fontWeight(.medium)
                .foregroundColor(.text)
            }
            
            if queueManager.failedCount > 0 {
              HStack {
                Text("Failed:")
                  .font(.peatedCaption)
                  .foregroundColor(.textSecondary)
                
                Text("\(queueManager.failedCount) operations")
                  .font(.peatedCaption)
                  .fontWeight(.medium)
                  .foregroundColor(.danger)
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
                    .foregroundColor(.textSecondary)
                  
                  Spacer()
                  
                  Text("\(count)")
                    .font(.peatedCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.text)
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
              .foregroundColor(.info)
            }
            .padding(.top, 8)
          }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
      }
      
      // Network Preferences
      VStack(alignment: .leading, spacing: 12) {
        Text("Network Preferences")
          .font(.peatedHeadline)
          .foregroundColor(.text)
          .padding(.horizontal)
        
        Toggle("Load images on cellular", isOn: Binding(
          get: { UserDefaults.standard.bool(forKey: UserDefaults.NetworkKeys.loadImagesOnCellular) },
          set: { UserDefaults.standard.set($0, forKey: UserDefaults.NetworkKeys.loadImagesOnCellular) }
        ))
        .tint(.brand)
        .padding(.horizontal)
        
        Toggle("Sync on cellular", isOn: Binding(
          get: { UserDefaults.standard.bool(forKey: UserDefaults.NetworkKeys.syncOnCellular) },
          set: { UserDefaults.standard.set($0, forKey: UserDefaults.NetworkKeys.syncOnCellular) }
        ))
        .tint(.brand)
        .padding(.horizontal)
      }
      .padding(.vertical)
      .background(Color.surface)
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
    .background(Color.background)
    
    OfflineStatusView()
      .background(Color.background)
  }
}
#endif
