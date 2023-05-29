import CoreLocation

class LocationClient: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var requesting: Bool = false
    @Published var didRequest: Bool = false
    @Published var placeInfo:CLPlacemark?
    
    override init() {
        super.init()
        locationManager.delegate = self;
    }
    
    func isPermision() -> Bool {
        if (locationManager.authorizationStatus == .authorizedWhenInUse) {
            return true
        }
        return false
    }
    
    func requestLocation() {
        request()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        request()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
        requesting = false
        self.getAdrInfo()
        didRequest = true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        requesting = false
    }
    
    private func request() {
        if (locationManager.authorizationStatus == .authorizedWhenInUse) {
            requesting = true
            locationManager.requestLocation()
            
        }
    }
    
    private func getAdrInfo()  {
        
        let locations = CLLocation(latitude: location!.latitude, longitude: location!.longitude)
        CLGeocoder().reverseGeocodeLocation(locations) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            self.placeInfo = placemark
        }
    }
}
