import SwiftUI
import PeatedCore

struct NotesStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @FocusState private var isNotesFocused: Bool
    @State private var showFlavorPicker = false
    
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
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text("\(viewModel.selectedTags.count) flavors selected")
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
                    
                    // Show selected flavors as chips
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
                        Text("Tasting Notes")
                            .font(.headline)
                        
                        Text("What did you taste? (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal)
                    
                    // TextEditor styled like photo buttons
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $viewModel.notes)
                            .focused($isNotesFocused)
                            .scrollContentBackground(.hidden)  // Hide the default background
                            .padding(12)  // Internal padding for text
                            .frame(minHeight: 200)
                            .overlay(
                                // Placeholder text
                                Group {
                                    if viewModel.notes.isEmpty && !isNotesFocused {
                                        Text("Describe the aroma, taste, and finish...")
                                            .foregroundColor(.textSecondary)
                                            .padding(.top, 20)  // Adjusted for internal padding
                                            .padding(.leading, 17)  // Adjusted for internal padding
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                    .background(Color.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
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
        .sheet(isPresented: $showFlavorPicker) {
            FlavorPickerModal(selectedTags: $viewModel.selectedTags, isPresented: $showFlavorPicker)
        }
    }
}
