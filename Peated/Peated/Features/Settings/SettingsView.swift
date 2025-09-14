import SwiftUI
import PeatedCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeveloperSettings = false
    @State private var showingLogoutAlert = false
    @State private var model = ProfileModel()
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section("Account") {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text("@\(model.user?.username ?? "Loading...")")
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(model.user?.email ?? "Loading...")
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                
                // Developer Section (DEBUG only)
                #if DEBUG
                Section("Development") {
                    Button(action: {
                        showingDeveloperSettings = true
                    }) {
                        Label("Developer Settings", systemImage: "hammer")
                    }
                    .foregroundColor(.text)
                }
                #endif
                
                // Support Section
                Section("Support") {
                    Link(destination: URL(string: "https://github.com/dcramer/peated")!) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                            .foregroundColor(.textSecondary)
                    }
                    
                    Link(destination: URL(string: "https://peated.com")!) {
                        Label("Visit Peated.com", systemImage: "safari")
                    }
                }
                
                // Sign Out
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.danger)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .listRowBackground(Color.surface)
            .tint(.brand)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .background(Color.background)
        .sheet(isPresented: $showingDeveloperSettings) {
            DeveloperSettingsView()
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
        .task {
            await model.loadUser()
        }
    }
}

#Preview {
    SettingsView()
}
