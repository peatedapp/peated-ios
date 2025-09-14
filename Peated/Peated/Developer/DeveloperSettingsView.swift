import SwiftUI
import PeatedCore

struct DeveloperSettingsView: View {
    @StateObject private var settings = DeveloperSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false
    @State private var showingResetConfirmation = false
    @AppStorage("debug.cacheLogging") private var cacheLogging: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Environment", selection: $settings.apiEnvironment) {
                        ForEach(APIEnvironment.allCases, id: \.self) { env in
                            Label {
                                Text(env.rawValue)
                            } icon: {
                                Image(systemName: env.icon)
                                    .foregroundColor(env.color)
                            }
                            .tag(env)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: settings.apiEnvironment) { _ in
                        Task {
                            await APIManager.shared.refreshFromSettings()
                        }
                    }
                    
                    HStack {
                        Text("Current URL")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(settings.currentAPIURL.absoluteString)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    
                    Button {
                        UIPasteboard.general.string = settings.currentAPIURL.absoluteString
                        copiedToClipboard = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedToClipboard = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                            Text(copiedToClipboard ? "Copied!" : "Copy API URL")
                        }
                    }
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Changes take effect immediately for new API calls")
                }
                
                // Removed placeholder debug toggles that had no runtime effect.

                Section("Diagnostics") {
                    Button(role: .destructive) {
                        Task {
                            await NormalizedStore.shared.clear()
                            URLCache.shared.removeAllCachedResponses()
                        }
                    } label: {
                        Label("Wipe Cache", systemImage: "trash")
                    }
                    .help("Clears the in-app normalized cache and the URL cache. App behavior is unchanged; next reads will rehydrate on demand.")
                }
                
                Section("App Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Bundle ID")
                        Spacer()
                        Text(Bundle.main.bundleIdentifier ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Device")
                        Spacer()
                        Text(UIDevice.current.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("iOS Version")
                        Spacer()
                        Text(UIDevice.current.systemVersion)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Quick Navigation") {
                    NavigationLink(destination: BottleDetailView(bottleId: "1", bottleName: "Lagavulin 16")) {
                        Label("Sample Bottle (Lagavulin 16)", systemImage: "wineglass")
                    }
                    
                    NavigationLink(destination: TastingDetailView(
                        tastingId: "1",
                        onNavigateToProfile: { _ in },
                        onNavigateToBottle: { _ in }
                    )) {
                        Label("Sample Tasting", systemImage: "pencil.and.list.clipboard")
                    }
                    
                    NavigationLink(destination: EntityDetailView(entityId: "1", entityName: "Lagavulin Distillery")) {
                        Label("Sample Entity (Lagavulin Distillery)", systemImage: "building.2")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .tint(.brand)
            .listRowBackground(Color.surface)
            .navigationTitle("Developer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Developer Settings?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings.reset()
                    dismiss()
                }
            } message: {
                Text("This will reset all developer settings to their defaults.")
            }
        }
        .background(Color.background)
    }
}

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#if DEBUG
struct DeveloperSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperSettingsView()
    }
}
#endif
