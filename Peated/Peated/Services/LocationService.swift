import CoreLocation
import Foundation
import MapKit
import PeatedCore

@MainActor
class LocationService: NSObject, ObservableObject {
    /// MapKit and Core Location report no results, throttling, and network
    /// state through their own error domains. None of those are Peated bugs.
    private static func isExpectedLocationError(_ error: any Error) -> Bool {
        let domain = (error as NSError).domain
        return domain == MKError.errorDomain || domain == kCLErrorDomain
    }

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoadingLocation = false
    @Published var locationError: Error?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }

    /// The user or a device policy has switched location off for Peated.
    var isAccessDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            requestCurrentLocation()
        default:
            break
        }
    }

    func requestCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }

        isLoadingLocation = true
        locationError = nil
        locationManager.requestLocation()
    }

    func searchPlaces(query: String) async -> [Location] {
        guard !query.isEmpty else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        // If we have a current location, search nearby
        if let currentLocation {
            let region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            request.region = region
        }

        // Filter for points of interest that are relevant for drinking
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .restaurant,
            .cafe,
            .nightlife,
            .brewery,
            .winery,
            .hotel,
            .conventionCenter,
            .publicTransport
        ])

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            return response.mapItems.compactMap { item in
                guard let name = item.name else { return nil }

                let address = formatAddress(from: item.placemark)

                return Location(
                    id: item.placemark.coordinate.latitude.description + "," + item.placemark.coordinate.longitude
                        .description,
                    name: name,
                    address: address
                )
            }
        } catch {
            if !Self.isExpectedLocationError(error) {
                Telemetry.capture(error, feature: "location", operation: "search")
            }
            return []
        }
    }

    func reverseGeocodeLocation(_ location: CLLocation) async -> Location? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            let name = placemark.name ?? "Current Location"
            let address = formatAddress(from: placemark)

            return Location(
                id: "current",
                name: name,
                address: address
            )
        } catch {
            if !Self.isExpectedLocationError(error) {
                Telemetry.capture(error, feature: "location", operation: "geocode")
            }
            return nil
        }
    }

    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []

        if let name = placemark.name,
           name != placemark.subThoroughfare {
            addressComponents.append(name)
        } else {
            if let subThoroughfare = placemark.subThoroughfare {
                addressComponents.append(subThoroughfare)
            }
            if let thoroughfare = placemark.thoroughfare {
                addressComponents.append(thoroughfare)
            }
        }

        if let locality = placemark.locality {
            addressComponents.append(locality)
        }

        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }

        return addressComponents.joined(separator: ", ")
    }

    private func formatAddress(from placemark: MKPlacemark) -> String {
        var addressComponents: [String] = []

        if let subThoroughfare = placemark.subThoroughfare {
            addressComponents.append(subThoroughfare)
        }

        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }

        if let locality = placemark.locality {
            addressComponents.append(locality)
        }

        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }

        return addressComponents.joined(separator: ", ")
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                requestCurrentLocation()
            }
        }
    }

    nonisolated func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            isLoadingLocation = false
            currentLocation = locations.last
        }
    }

    nonisolated func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLoadingLocation = false
            locationError = error
            print("Location error: \(error)")
        }
    }
}
