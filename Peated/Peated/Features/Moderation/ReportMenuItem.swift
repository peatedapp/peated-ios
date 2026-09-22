import PeatedCore
import SwiftUI

/// The Report row for an `OverflowMenu`. Every screen uses this so the
/// wording, icon, and sheet are the same, and adding a new reportable
/// object is one line in its menu.
///
/// It needs a `reportSheet()` mount above it. Without one the row is hidden
/// and a debug build stops, so a missing mount cannot ship as a dead button.
struct ReportMenuItem: View {
    let target: ReportTarget

    @Environment(\.reportPresenter) private var presenter

    var body: some View {
        if let presenter {
            Button {
                presenter.present(target)
            } label: {
                Label("Report", systemImage: "flag")
            }
        } else {
            missingMount
        }
    }

    private var missingMount: some View {
        assertionFailure("ReportMenuItem needs a reportSheet() mount above it")
        return EmptyView()
    }
}
