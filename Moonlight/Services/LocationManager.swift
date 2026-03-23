import Foundation
import CoreLocation

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published var latitude: Double = 41.0082 // Istanbul default
    @Published var longitude: Double = 28.9784
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var hasLocation: Bool = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.hasLocation = true
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        // Keep using Istanbul defaults
        Task { @MainActor in
            self.hasLocation = true
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.locationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            } else {
                // Use defaults even without permission
                self.hasLocation = true
            }
        }
    }
}
