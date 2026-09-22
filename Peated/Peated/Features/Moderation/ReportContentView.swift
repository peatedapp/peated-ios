import PeatedCore
import SwiftUI

/// Sheet that reports a tasting, review, comment, or member to moderators.
/// It closes only after the server accepts the report.
struct ReportContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: ReportModel

    init(target: ReportTarget) {
        _model = State(initialValue: ReportModel(target: target))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(
                        "Tell us what is wrong with \(model.target.subject). "
                            + "Moderators review every report and never share who sent it."
                    )
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    FormSection("Reason") {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            reasonRow(reason)
                        }
                    }

                    FormSection("Details (optional)") {
                        TextField(
                            "Anything that helps moderators understand the problem.",
                            text: $model.details,
                            axis: .vertical
                        )
                        .lineLimit(3 ... 6)
                        .disabled(model.isSending)
                        .accessibilityIdentifier("reportDetailsField")
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.danger)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                    }

                    Button(action: send) {
                        Group {
                            if model.isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .onBrand))
                            } else {
                                Text("Send Report")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.onBrand)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.brand)
                        .cornerRadius(12)
                    }
                    .disabled(model.isSending)
                    .accessibilityIdentifier("sendReportButton")
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationChrome()
            .navigationTitle("Report to Moderators")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(model.isSending)
                }
            }
        }
        .screenBackground()
        .interactiveDismissDisabled(model.isSending)
    }

    private func reasonRow(_ reason: ReportReason) -> some View {
        Button {
            model.reason = reason
        } label: {
            HStack {
                Text(reason.label)
                    .foregroundColor(.text)
                Spacer()
                if model.reason == reason {
                    Image(systemName: "checkmark")
                        .foregroundColor(.brand)
                }
            }
            .frame(minHeight: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(model.isSending)
        .accessibilityAddTraits(model.reason == reason ? [.isSelected] : [])
    }

    private func send() {
        Task {
            if await model.send() {
                dismiss()
                ToastManager.shared.showSuccess("Report sent. Moderators will review it.")
            }
        }
    }
}

#Preview {
    ReportContentView(target: .user(id: "1", username: "islaydrinker"))
}
