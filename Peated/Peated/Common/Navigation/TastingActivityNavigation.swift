import PeatedCore
import SwiftUI

enum TastingActivityNavigationDestination: Hashable {
    case tasting(id: String, seed: TastingFeedItem?)
    case profile(id: String, username: String, pictureUrl: String?)
    case bottle(id: String)
}

private struct TastingActivityNavigationDestinations: ViewModifier {
    @Binding var path: NavigationPath

    func body(content: Content) -> some View {
        content.navigationDestination(for: TastingActivityNavigationDestination.self) { destination in
            switch destination {
            case let .tasting(id, seed):
                TastingDetailView(
                    tastingId: id,
                    seed: seed,
                    onNavigateToProfile: { userId in
                        path.append(TastingActivityNavigationDestination.profile(
                            id: userId,
                            username: "",
                            pictureUrl: nil
                        ))
                    },
                    onNavigateToBottle: { bottleId in
                        path.append(TastingActivityNavigationDestination.bottle(id: bottleId))
                    }
                )
            case let .profile(id, username, pictureUrl):
                ProfileView(
                    userId: id,
                    seed: User(id: id, email: "", username: username).withPicture(pictureUrl),
                    onNavigateToProfile: { userId in
                        path.append(TastingActivityNavigationDestination.profile(
                            id: userId,
                            username: "",
                            pictureUrl: nil
                        ))
                    },
                    onNavigateToTasting: { tastingId in
                        path.append(TastingActivityNavigationDestination.tasting(id: tastingId, seed: nil))
                    },
                    onNavigateToBottle: { bottleId in
                        path.append(TastingActivityNavigationDestination.bottle(id: bottleId))
                    }
                )
            case let .bottle(id):
                BottleDetailView(
                    bottleId: id,
                    bottleName: nil,
                    navigationPath: $path
                )
            }
        }
    }
}

extension View {
    func tastingActivityNavigationDestinations(path: Binding<NavigationPath>) -> some View {
        modifier(TastingActivityNavigationDestinations(path: path))
    }
}
