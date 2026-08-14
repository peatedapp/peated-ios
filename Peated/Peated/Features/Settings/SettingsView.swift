import PeatedCore
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeveloperSettings = false
    @State private var showingLogoutAlert = false
    @State private var model = ProfileModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Account Section
                    FormSection("Account") {
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
                        FormSection("Development") {
                            Button(action: {
                                showingDeveloperSettings = true
                            }) {
                                // Make row full-width and left-aligned
                                Label("Developer Settings", systemImage: "hammer")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .foregroundColor(.text)
                        }
                    #endif

                    // Support Section
                    FormSection("Support") {
                        Link(destination: URL(string: "https://github.com/dcramer/peated")!) {
                            // Make row full-width and left-aligned
                            Label("Help & Support", systemImage: "questionmark.circle")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                    }

                    // About Section
                    FormSection("About") {
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
                    FormSection(nil) {
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
                .padding(.vertical)
            }
            .navigationChrome()
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
        .screenBackground()
        .sheet(isPresented: $showingDeveloperSettings) {
            DeveloperSettingsView()
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
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
