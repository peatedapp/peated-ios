import Observation
import PeatedCore
import SwiftUI

/// Opens the report sheet for the screens below a `reportSheet()` mount.
///
/// `reportSheet()` creates one presenter, attaches the sheet, and puts the
/// presenter in the environment, so `ReportMenuItem` finds the nearest mount.
/// The app root mounts one for the main navigation. A screen shown inside
/// another sheet mounts its own, because iOS will not present a second sheet
/// from the root while one is up.
@Observable
@MainActor
final class ReportPresenter {
    var target: ReportTarget?

    func present(_ target: ReportTarget) {
        self.target = target
    }
}

extension EnvironmentValues {
    /// The nearest `reportSheet()` mount, or nil when no ancestor has one.
    @Entry var reportPresenter: ReportPresenter?
}

extension View {
    /// Presents `ReportContentView` for every `ReportMenuItem` below this view.
    func reportSheet() -> some View {
        modifier(ReportSheetModifier())
    }
}

private struct ReportSheetModifier: ViewModifier {
    @State private var presenter = ReportPresenter()

    func body(content: Content) -> some View {
        content
            .sheet(item: $presenter.target) { target in
                ReportContentView(target: target)
            }
            .environment(\.reportPresenter, presenter)
    }
}
