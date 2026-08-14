import SwiftUI

struct EntityDetailTestView: View {
    var body: some View {
        NavigationStack {
            EntityDetailView(entityId: "73", entityName: "Springbank")
        }
    }
}

#Preview {
    EntityDetailTestView()
}
