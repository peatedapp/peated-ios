import SwiftUI
import PeatedCore

struct NotesStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @FocusState private var isNotesFocused: Bool
    @State private var showFlavorPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add tasting notes")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let bottle = viewModel.selectedBottle {
                        Text("Describe your experience with \(bottle.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Flavor Profile Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Flavor Profile")
                        .font(.headline)
                    
                    Button(action: {
                        showFlavorPicker = true
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.body)
                            
                            if viewModel.selectedTags.isEmpty {
                                Text("Select flavor notes")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(viewModel.selectedTags.count) flavors selected")
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    // Show selected flavors as chips
                    if !viewModel.selectedTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.selectedTags.sorted(), id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Button(action: {
                                            viewModel.selectedTags.remove(tag)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Notes Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tasting Notes")
                        .font(.headline)
                    
                    Text("What did you taste? (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $viewModel.notes)
                            .focused($isNotesFocused)
                            .scrollContentBackground(.hidden)  // Hide the default background
                            .padding(12)  // Internal padding for text
                            .background(
                                Color(.systemGray6)  // Very subtle background - almost imperceptible
                                    .cornerRadius(12)  // Soft rounded corners
                            )
                            .frame(minHeight: 200)
                            .overlay(
                                // Placeholder text
                                Group {
                                    if viewModel.notes.isEmpty && !isNotesFocused {
                                        Text("Describe the aroma, taste, and finish...")
                                            .foregroundColor(.secondary)
                                            .padding(.top, 20)  // Adjusted for internal padding
                                            .padding(.leading, 17)  // Adjusted for internal padding
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                    
                    // Character count
                    HStack {
                        Spacer()
                        Text("\(viewModel.notes.count)/500")
                            .font(.caption)
                            .foregroundColor(viewModel.notes.count > 500 ? .red : .secondary)
                    }
                    
                    // Quick suggestions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Need inspiration?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Consider describing:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("The nose/aroma", systemImage: "wind")
                            Label("Initial taste", systemImage: "mouth")
                            Label("The finish", systemImage: "timer")
                            Label("How it compares to others", systemImage: "arrow.left.arrow.right")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100) // Space for navigation buttons
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showFlavorPicker) {
            FlavorPickerModal(selectedTags: $viewModel.selectedTags, isPresented: $showFlavorPicker)
        }
    }
}