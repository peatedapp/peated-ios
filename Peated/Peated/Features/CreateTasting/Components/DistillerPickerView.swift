import PeatedCore
import SwiftUI

/// Searches the catalog for a distillery, or offers to add a new one by name.
/// Pushed from the Add Bottle form. Picking a row hands it back and pops.
struct DistillerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selected: [CreateBottleInput.Distiller]
    let entityRepository: any EntityRepositoryProtocol
    let onSelect: (CreateBottleInput.Distiller) -> Void

    @State private var query = ""
    @State private var results: [Entity] = []
    @State private var isLoading = false
    @State private var searchFailed = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SearchInput(
                    placeholder: "Search distilleries",
                    text: $query,
                    isFocused: $searchFocused
                )

                if searchFailed {
                    Text("Unable to search distilleries. Keep typing or try again.")
                        .font(.caption)
                        .foregroundColor(.danger)
                }

                if let createName {
                    optionRow(title: "Add “\(createName)”", subtitle: nil, systemImage: "plus") {
                        pick(.new(name: createName))
                    }
                }

                ForEach(results) { entity in
                    if let id = Int(entity.id) {
                        optionRow(
                            title: entity.name,
                            subtitle: location(of: entity),
                            systemImage: "building.columns"
                        ) {
                            pick(.existing(id: id, name: entity.name))
                        }
                    }
                }

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if !trimmedQuery.isEmpty, results.isEmpty, !searchFailed {
                    Text("No matches.")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding()
        }
        .background(Color.background)
        .navigationTitle("Distilled by")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { searchFocused = true }
        .task(id: trimmedQuery) {
            await search(trimmedQuery)
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Offer to add the typed name unless the catalog already has it.
    private var createName: String? {
        let name = trimmedQuery
        guard !name.isEmpty, !isLoading else { return nil }
        let exists = results.contains { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
        return exists ? nil : name
    }

    private func optionRow(
        title: String,
        subtitle: String?,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundColor(.textSecondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.text)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .inputBox()
        }
        .buttonStyle(.plain)
    }

    private func location(of entity: Entity) -> String? {
        let parts = [entity.region, entity.country].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func pick(_ distiller: CreateBottleInput.Distiller) {
        if !selected.contains(distiller) {
            onSelect(distiller)
        }
        dismiss()
    }

    private func search(_ text: String) async {
        guard !text.isEmpty else {
            results = []
            searchFailed = false
            isLoading = false
            return
        }

        isLoading = true
        // Debounce typing. A newer query cancels this task.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        do {
            let found = try await entityRepository.searchEntities(query: text, limit: 25)
            guard !Task.isCancelled else { return }
            results = found
            searchFailed = false
        } catch is CancellationError {
            return
        } catch {
            Telemetry.capture(error, feature: "create_bottle", operation: "search_distillers")
            results = []
            searchFailed = true
        }
        isLoading = false
    }
}
