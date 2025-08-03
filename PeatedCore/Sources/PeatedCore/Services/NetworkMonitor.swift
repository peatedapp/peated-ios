import Foundation
import Network

/// NetworkMonitor provides real-time network status monitoring for offline support.
/// It uses Apple's Network framework to detect connectivity changes and connection types.
@Observable
@MainActor
public class NetworkMonitor {
  /// Shared singleton instance for app-wide network monitoring
  public static let shared = NetworkMonitor()
  
  /// Current network connectivity status
  public private(set) var isConnected = true
  
  /// Whether the current connection is expensive (e.g., cellular roaming)
  public private(set) var isExpensive = false
  
  /// Whether the current connection is constrained (e.g., low data mode)
  public private(set) var isConstrained = false
  
  /// Type of network connection currently active
  public private(set) var connectionType: ConnectionType = .unknown
  
  /// Represents the type of network connection
  public enum ConnectionType {
    case wifi
    case cellular
    case wiredEthernet
    case unknown
    
    /// User-friendly description of the connection type
    public var displayName: String {
      switch self {
      case .wifi: return "Wi-Fi"
      case .cellular: return "Cellular"
      case .wiredEthernet: return "Ethernet"
      case .unknown: return "Unknown"
      }
    }
  }
  
  // Private properties
  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "com.peated.networkmonitor", qos: .utility)
  
  /// Private initializer to enforce singleton pattern
  private init() {
    startMonitoring()
  }
  
  /// Starts network monitoring and sets up path update handler
  private func startMonitoring() {
    monitor.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        guard let self = self else { return }
        
        // Update connectivity status
        self.isConnected = path.status == .satisfied
        self.isExpensive = path.isExpensive
        self.isConstrained = path.isConstrained
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
          self.connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
          self.connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
          self.connectionType = .wiredEthernet
        } else {
          self.connectionType = .unknown
        }
        
        // Log network status change for debugging
        print("NetworkMonitor: Status changed - connected: \(self.isConnected), type: \(self.connectionType)")
        
        // Notify offline queue to process pending operations when connectivity is restored
        if path.status == .satisfied {
          await OfflineQueueManager.shared.processPendingOperations()
        }
      }
    }
    
    // Start monitoring on background queue
    monitor.start(queue: queue)
  }
  
  /// Stops network monitoring (useful for testing)
  public func stopMonitoring() {
    monitor.cancel()
  }
  
  /// Checks if we should load images based on connection type and user preferences
  public func shouldLoadImages() -> Bool {
    // Always load on WiFi
    if connectionType == .wifi {
      return true
    }
    
    // Check user preferences for cellular
    if connectionType == .cellular {
      // Don't load on expensive connections
      if isExpensive {
        return false
      }
      
      // Check user preference
      return UserDefaults.standard.bool(forKey: "loadImagesOnCellular")
    }
    
    // Don't load when offline
    return false
  }
  
  /// Checks if we should perform background sync operations
  public func shouldPerformBackgroundSync() -> Bool {
    // Only sync on WiFi or non-expensive connections
    guard isConnected else { return false }
    
    if connectionType == .wifi {
      return true
    }
    
    if connectionType == .cellular && !isExpensive && !isConstrained {
      // Check user preference for cellular sync
      return UserDefaults.standard.bool(forKey: "syncOnCellular")
    }
    
    return false
  }
  
  /// Debug description of current network state
  public var debugDescription: String {
    """
    NetworkMonitor State:
    - Connected: \(isConnected)
    - Type: \(connectionType.displayName)
    - Expensive: \(isExpensive)
    - Constrained: \(isConstrained)
    """
  }
}

// MARK: - Notifications

public extension Notification.Name {
  /// Posted when network connectivity status changes
  static let networkStatusChanged = Notification.Name("com.peated.networkStatusChanged")
}

// MARK: - UserDefaults Keys

public extension UserDefaults {
  /// Keys for network-related user preferences
  public enum NetworkKeys {
    public static let loadImagesOnCellular = "com.peated.loadImagesOnCellular"
    public static let syncOnCellular = "com.peated.syncOnCellular"
  }
}