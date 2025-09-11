# Push Notifications

## Overview

Peated uses push notifications to keep users engaged with timely updates about their whisky community. Notifications are delivered via Apple Push Notification service (APNs) and include social interactions, achievements, and personalized recommendations.

## Notification Types

### Social Notifications

```swift
enum NotificationType: String, Codable {
    // Social interactions
    case newToast = "new_toast"
    case newComment = "new_comment"
    case newFollower = "new_follower"
    case friendJoined = "friend_joined"
    case mentionInComment = "mention_in_comment"
    case taggedInTasting = "tagged_in_tasting"
    
    // Achievements & Milestones
    case achievementUnlocked = "achievement_unlocked"
    case milestoneReached = "milestone_reached"
    case weeklyStats = "weekly_stats"
    
    // Recommendations
    case bottleRecommendation = "bottle_recommendation"
    case friendTastingNearby = "friend_tasting_nearby"
    case newBottleInWishlist = "new_bottle_in_wishlist"
    
    // System
    case appUpdate = "app_update"
    case dataExportReady = "data_export_ready"
}
```

## Implementation

### App Delegate Setup

```swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure push notifications
        configurePushNotifications()
        
        // Check if launched from notification
        if let notification = launchOptions?[.remoteNotification] as? [String: Any] {
            handleNotificationLaunch(notification)
        }
        
        return true
    }
    
    // MARK: - Push Configuration
    private func configurePushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        // Set notification categories
        setNotificationCategories()
        
        // Register for remote notifications
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func setNotificationCategories() {
        // Toast notification actions
        let toastAction = UNNotificationAction(
            identifier: "TOAST_ACTION",
            title: "Toast Back",
            options: [.foreground]
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: [.foreground]
        )
        
        // Comment notification actions
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Write a comment..."
        )
        
        // Categories
        let toastCategory = UNNotificationCategory(
            identifier: "TOAST_CATEGORY",
            actions: [toastAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        let commentCategory = UNNotificationCategory(
            identifier: "COMMENT_CATEGORY",
            actions: [replyAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            toastCategory,
            commentCategory
        ])
    }
    
    // MARK: - Token Registration
    func application(_ application: UIApplication, 
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        Task {
            await NotificationManager.shared.registerDeviceToken(token)
        }
    }
    
    func application(_ application: UIApplication, 
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for push notifications: \(error)")
    }
}
```

### Notification Manager

```swift
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    @Published var pendingNotification: PendingNotification?
    @Published var unreadCount = 0
    
    private let apiClient = PeatedAPI.shared
    
    override init() {
        super.init()
        checkPermissionStatus()
    }
    
    // MARK: - Permission Management
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            hasPermission = granted
            
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Device Token
    func registerDeviceToken(_ token: String) async {
        do {
            try await apiClient.registerDeviceToken(
                token: token,
                platform: "ios",
                appVersion: Bundle.main.appVersion
            )
        } catch {
            print("Failed to register device token: \(error)")
        }
    }
    
    // MARK: - Handle Notifications
    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        guard let aps = userInfo["aps"] as? [String: Any],
              let typeString = userInfo["type"] as? String,
              let type = NotificationType(rawValue: typeString) else {
            return
        }
        
        // Update badge count
        if let badge = aps["badge"] as? Int {
            UIApplication.shared.applicationIconBadgeNumber = badge
            unreadCount = badge
        }
        
        // Create pending notification for navigation
        pendingNotification = PendingNotification(
            type: type,
            userInfo: userInfo
        )
        
        // Handle specific notification types
        switch type {
        case .newToast:
            handleNewToast(userInfo)
        case .newComment:
            handleNewComment(userInfo)
        case .newFollower:
            handleNewFollower(userInfo)
        case .achievementUnlocked:
            handleAchievement(userInfo)
        default:
            break
        }
    }
    
    // MARK: - Notification Handlers
    private func handleNewToast(_ userInfo: [AnyHashable: Any]) {
        guard let tastingId = userInfo["tasting_id"] as? String,
              let userName = userInfo["user_name"] as? String else {
            return
        }
        
        // Update local data
        Task {
            if let tasting = await fetchTasting(id: tastingId) {
                tasting.toastCount += 1
                tasting.hasToasted = true
            }
        }
        
        // Show in-app notification if active
        if UIApplication.shared.applicationState == .active {
            showInAppNotification(
                title: "New Toast!",
                message: "\(userName) toasted your tasting",
                type: .toast
            )
        }
    }
    
    private func handleNewComment(_ userInfo: [AnyHashable: Any]) {
        guard let tastingId = userInfo["tasting_id"] as? String,
              let comment = userInfo["comment_preview"] as? String,
              let userName = userInfo["user_name"] as? String else {
            return
        }
        
        // Navigate if tapped
        if let pending = pendingNotification {
            navigateToTasting(id: tastingId, scrollToComments: true)
        }
    }
    
    // MARK: - In-App Notifications
    private func showInAppNotification(title: String, message: String, type: InAppNotificationType) {
        InAppNotificationView.show(
            title: title,
            message: message,
            type: type,
            action: {
                // Handle tap
                if let pending = self.pendingNotification {
                    self.handlePendingNotification(pending)
                }
            }
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Show notification even when app is in foreground
        if UIApplication.shared.applicationState == .active {
            // Show custom in-app notification
            handleNotification(notification.request.content.userInfo)
            completionHandler([])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Handle notification tap or action
        switch response.actionIdentifier {
        case "TOAST_ACTION":
            handleToastAction(response.notification)
        case "REPLY_ACTION":
            if let textResponse = response as? UNTextInputNotificationResponse {
                handleReplyAction(response.notification, text: textResponse.userText)
            }
        case UNNotificationDefaultActionIdentifier:
            handleNotification(response.notification.request.content.userInfo)
        default:
            break
        }
        
        completionHandler()
    }
}
```

### In-App Notification View

```swift
struct InAppNotificationView: View {
    let title: String
    let message: String
    let type: InAppNotificationType
    let action: (() -> Void)?
    
    @State private var isShowing = false
    @State private var offset: CGFloat = -100
    
    enum InAppNotificationType {
        case toast
        case comment
        case follow
        case achievement
        
        var icon: String {
            switch self {
            case .toast: return "hands.clap.fill"
            case .comment: return "bubble.left.fill"
            case .follow: return "person.badge.plus"
            case .achievement: return "trophy.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .toast: return .yellow
            case .comment: return .blue
            case .follow: return .green
            case .achievement: return .purple
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .padding(.horizontal)
        .offset(y: offset)
        .onTapGesture {
            action?()
            dismiss()
        }
        .onAppear {
            show()
        }
    }
    
    private func show() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isShowing = true
            offset = 20
        }
        
        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            dismiss()
        }
    }
    
    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = -100
        }
    }
    
    static func show(title: String, message: String, type: InAppNotificationType, action: (() -> Void)? = nil) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        
        let notification = InAppNotificationView(
            title: title,
            message: message,
            type: type,
            action: action
        )
        
        let hostingController = UIHostingController(rootView: notification)
        hostingController.view.backgroundColor = .clear
        
        window.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: window.trailingAnchor)
        ])
        
        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            hostingController.view.removeFromSuperview()
        }
    }
}
```

### Notification Settings

```swift
struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    
    var body: some View {
        List {
            Section {
                Toggle("Push Notifications", isOn: $viewModel.pushEnabled)
                    .onChange(of: viewModel.pushEnabled) { enabled in
                        Task {
                            await viewModel.updatePushSetting(enabled)
                        }
                    }
            } footer: {
                Text("Receive notifications about toasts, comments, and more")
            }
            
            Section("Social Notifications") {
                Toggle("New Toasts", isOn: $viewModel.toastsEnabled)
                Toggle("New Comments", isOn: $viewModel.commentsEnabled)
                Toggle("New Followers", isOn: $viewModel.followersEnabled)
                Toggle("Friend Activity", isOn: $viewModel.friendActivityEnabled)
                Toggle("Mentions", isOn: $viewModel.mentionsEnabled)
            }
            
            Section("Achievement Notifications") {
                Toggle("Achievements Unlocked", isOn: $viewModel.achievementsEnabled)
                Toggle("Milestones Reached", isOn: $viewModel.milestonesEnabled)
                Toggle("Weekly Stats", isOn: $viewModel.weeklyStatsEnabled)
            }
            
            Section("Other Notifications") {
                Toggle("Recommendations", isOn: $viewModel.recommendationsEnabled)
                Toggle("App Updates", isOn: $viewModel.appUpdatesEnabled)
            }
            
            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $viewModel.quietHoursEnabled)
                
                if viewModel.quietHoursEnabled {
                    DatePicker("From", selection: $viewModel.quietHoursStart, displayedComponents: .hourAndMinute)
                    DatePicker("To", selection: $viewModel.quietHoursEnd, displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
class NotificationSettingsViewModel: ObservableObject {
    @Published var pushEnabled = true
    @Published var toastsEnabled = true
    @Published var commentsEnabled = true
    @Published var followersEnabled = true
    @Published var friendActivityEnabled = true
    @Published var mentionsEnabled = true
    @Published var achievementsEnabled = true
    @Published var milestonesEnabled = true
    @Published var weeklyStatsEnabled = true
    @Published var recommendationsEnabled = true
    @Published var appUpdatesEnabled = true
    @Published var quietHoursEnabled = false
    @Published var quietHoursStart = Date()
    @Published var quietHoursEnd = Date()
    
    private let apiClient = PeatedAPI.shared
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        // Load from UserDefaults or API
    }
    
    func updatePushSetting(_ enabled: Bool) async {
        if enabled {
            let granted = await NotificationManager.shared.requestPermission()
            pushEnabled = granted
        } else {
            // Disable on server
            try? await apiClient.updateNotificationSettings(enabled: false)
        }
    }
}
```

## Notification Payloads

### Toast Notification
```json
{
  "aps": {
    "alert": {
      "title": "New Toast!",
      "body": "Sarah toasted your Lagavulin 16 tasting"
    },
    "badge": 1,
    "sound": "toast.caf",
    "category": "TOAST_CATEGORY"
  },
  "type": "new_toast",
  "tasting_id": "12345",
  "user_id": "67890",
  "user_name": "Sarah",
  "user_avatar": "https://..."
}
```

### Comment Notification
```json
{
  "aps": {
    "alert": {
      "title": "New Comment",
      "body": "Mike: \"Great choice! How does it compare to the 12?\""
    },
    "badge": 2,
    "sound": "default",
    "category": "COMMENT_CATEGORY"
  },
  "type": "new_comment",
  "tasting_id": "12345",
  "comment_id": "23456",
  "user_id": "78901",
  "user_name": "Mike",
  "comment_preview": "Great choice! How does it compare to the 12?"
}
```

## Deep Linking

### Navigation Handler

```swift
struct NotificationNavigator {
    static func navigate(to notification: PendingNotification) {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else { return }
        
        switch notification.type {
        case .newToast, .newComment:
            if let tastingId = notification.userInfo["tasting_id"] as? String {
                navigateToTasting(id: tastingId)
            }
            
        case .newFollower:
            if let userId = notification.userInfo["user_id"] as? String {
                navigateToProfile(userId: userId)
            }
            
        case .achievementUnlocked:
            navigateToAchievements()
            
        case .bottleRecommendation:
            if let bottleId = notification.userInfo["bottle_id"] as? String {
                navigateToBottle(id: bottleId)
            }
            
        default:
            break
        }
    }
}
```

## Analytics

### Notification Events

```swift
enum NotificationEvent: String {
    case received = "notification_received"
    case opened = "notification_opened"
    case actionTaken = "notification_action"
    case settingsChanged = "notification_settings_changed"
    
    func track(properties: [String: Any] = [:]) {
        Analytics.track(event: self.rawValue, properties: properties)
    }
}

// Usage
NotificationEvent.opened.track(properties: [
    "type": "new_toast",
    "source": "push",
    "tasting_id": "12345"
])
```

## Best Practices

### Timing
- Respect quiet hours
- Batch similar notifications
- Delay non-urgent updates
- Consider time zones

### Content
- Clear, actionable messages
- Personal and relevant
- Proper grammar
- Emoji sparingly

### Frequency
- Limit per user per day
- Prioritize important events
- Allow granular control
- Monitor opt-out rates