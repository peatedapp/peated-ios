import PeatedCore
import SwiftUI

struct NotesStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @FocusState private var isNotesFocused: Bool
    @State private var showNotesPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add tasting notes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.text)

                    if let bottle = viewModel.selectedBottle {
                        Text("Describe your experience with \(bottle.name)")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 32)

                // Structured tasting notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes")
                        .font(.headline)

                    Text("What flavors and aromas come to mind? (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    Button(action: {
                        showNotesPicker = true
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.body)

                            if viewModel.selectedTags.isEmpty {
                                Text("Select tasting notes")
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text("\(viewModel.selectedTags.count) notes selected")
                                    .foregroundColor(.text)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding()
                        .background(Color.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    // Show selected notes as chips
                    if !viewModel.selectedTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.selectedTags.sorted(), id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.text)

                                        Button(action: {
                                            viewModel.selectedTags.remove(tag)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.surfaceSubtle)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)

                // Notes Section
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comments")
                            .font(.headline)

                        Text("Anything else you want to remember? (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal)

                    TextArea(
                        label: nil,
                        placeholder: "Tell us how you really feel.",
                        text: $viewModel.notes,
                        minHeight: 200
                    )
                    .focused($isNotesFocused)
                    .padding(.horizontal)

                    // Character count
                    HStack {
                        Spacer()
                        Text("\(viewModel.notes.count)/500")
                            .font(.caption)
                            .foregroundColor(viewModel.notes.count > 500 ? .danger : .textSecondary)
                    }
                    .padding(.horizontal)

                    // Quick suggestions styled like photo tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Need inspiration?")
                            .font(.headline)

                        Text("Consider describing:")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "wind")
                                    .font(.caption)
                                    .foregroundColor(.brand)
                                    .frame(width: 20)
                                Text("The nose/aroma")
                                    .font(.caption)
                                    .foregroundColor(.text)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "mouth")
                                    .font(.caption)
                                    .foregroundColor(.brand)
                                    .frame(width: 20)
                                Text("Initial taste")
                                    .font(.caption)
                                    .foregroundColor(.text)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                    .foregroundColor(.brand)
                                    .frame(width: 20)
                                Text("The finish")
                                    .font(.caption)
                                    .foregroundColor(.text)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.caption)
                                    .foregroundColor(.brand)
                                    .frame(width: 20)
                                Text("How it compares to others")
                                    .font(.caption)
                                    .foregroundColor(.text)
                            }
                        }
                    }
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .padding(.bottom, 100) // Space for navigation buttons
        }
        .background(Color.background)
        .scrollDismissesKeyboard(.interactively)
        .task(id: viewModel.selectedBottle?.id) {
            await viewModel.loadSuggestedTags()
        }
        .sheet(isPresented: $showNotesPicker) {
            TastingNotesPicker(
                selectedTags: $viewModel.selectedTags,
                isPresented: $showNotesPicker,
                tags: viewModel.suggestedTags,
                isLoading: viewModel.isLoadingSuggestedTags,
                errorMessage: viewModel.suggestedTagsError
            )
        }
    }
}
