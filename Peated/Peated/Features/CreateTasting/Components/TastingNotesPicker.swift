import PeatedCore
import SwiftUI

struct TastingNotesPicker: View {
    private struct TagGroup: Identifiable {
        let category: String
        let tags: [TastingTag]
        var id: String {
            category
        }
    }

    @Binding var selectedTags: Set<String>
    @Binding var isPresented: Bool
    let tags: [TastingTag]
    let isLoading: Bool
    let errorMessage: String?

    @State private var query = ""
    @State private var tempSelection: Set<String>

    init(
        selectedTags: Binding<Set<String>>,
        isPresented: Binding<Bool>,
        tags: [TastingTag],
        isLoading: Bool,
        errorMessage: String?
    ) {
        _selectedTags = selectedTags
        _isPresented = isPresented
        self.tags = tags
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        _tempSelection = State(initialValue: selectedTags.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchInput(
                    placeholder: "Search flavors and aromas",
                    text: $query
                )
                .padding(.horizontal)
                .padding(.vertical, 12)

                List {
                    if !tempSelection.isEmpty {
                        Section("Selected") {
                            ForEach(tempSelection.sorted(), id: \.self) { name in
                                noteRow(name: name, category: nil)
                            }
                        }
                    }

                    if isLoading, tags.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView("Loading notes…")
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    } else if let errorMessage, tags.isEmpty {
                        ContentUnavailableView(
                            "Notes Unavailable",
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage)
                        )
                        .listRowBackground(Color.clear)
                    } else if query.isEmpty {
                        ForEach(groupedTags) { group in
                            Section(categoryName(group.category)) {
                                ForEach(group.tags) { tag in
                                    noteRow(name: tag.name, category: nil)
                                }
                            }
                        }
                    } else if filteredTags.isEmpty {
                        ContentUnavailableView.search(text: query)
                            .listRowBackground(Color.clear)
                    } else {
                        Section("Results") {
                            ForEach(filteredTags) { tag in
                                noteRow(name: tag.name, category: categoryName(tag.category))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .background(Color.background)
            .navigationTitle("Tasting Notes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedTags = tempSelection
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var filteredTags: [TastingTag] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedQuery.isEmpty else { return tags }

        return tags.filter { tag in
            tag.name.lowercased().contains(normalizedQuery)
                || tag.category.lowercased().contains(normalizedQuery)
                || tag.synonyms.contains { $0.lowercased().contains(normalizedQuery) }
        }
    }

    private var groupedTags: [TagGroup] {
        var groups: [String: [TastingTag]] = [:]
        var order: [String] = []

        for tag in tags {
            if groups[tag.category] == nil {
                groups[tag.category] = []
                order.append(tag.category)
            }
            groups[tag.category, default: []].append(tag)
        }

        return order.map { TagGroup(category: $0, tags: groups[$0] ?? []) }
    }

    private func categoryName(_ value: String) -> String {
        value.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func noteRow(name: String, category: String?) -> some View {
        Button {
            if tempSelection.contains(name) {
                tempSelection.remove(name)
            } else {
                tempSelection.insert(name)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name.capitalized)
                        .foregroundColor(.text)

                    if let category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                if tempSelection.contains(name) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brand)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.formSurface)
        .listRowSeparatorTint(Color.formBorder)
    }
}
