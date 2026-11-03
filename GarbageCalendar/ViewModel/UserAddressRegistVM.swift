import Foundation
import CoreLocation
import SwiftUI

/// The GPS result is usable immediately; reverse geocoding is not a search prerequisite.
class UserAddressRegistVM: BaseVM, CLLocationManagerDelegate {
    @Published var model = UserAddressRegistModel()
    @Published var activie = false
    @Published var areaQuery = ""
    @Published var postalQuery = ""
    @Published var postalCandidates: [ApiAddress] = []
    @Published var showPostalCandidates = false
    private var geocodeRequestID: UUID?
    @Published var permissionDenied = false
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var awaitingLocation = false
    private var permissionCompletion: (() -> Void)?
    private var timeout: Task<Void, Never>?

    override init() {
        super.init()
        if let saved = loadUserAddressRegistModel() { model = saved }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // Tutorial asks only for permission; actual location lookup happens after setup.
    func requestPermission(completion: @escaping () -> Void) {
        guard locationManager.authorizationStatus == .notDetermined else {
            completion()
            return
        }
        permissionCompletion = completion
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        guard !isShowProgres else { return }
        permissionDenied = false
        awaitingLocation = true
        isShowProgres = true
        switch locationManager.authorizationStatus {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: locate()
        default: denied()
        }
    }

    private func locate() {
        locationManager.requestLocation()
        timeout?.cancel()
        timeout = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(20)) } catch { return }
            guard let self, self.awaitingLocation else { return }
            self.awaitingLocation = false
            self.isShowProgres = false
            self.showPopup(withMessage: "現在地を取得できませんでした。再試行するか、郵便番号で検索してください。")
        }
    }

    private func denied() {
        awaitingLocation = false
        isShowProgres = false
        permissionDenied = true
        showPopup(withMessage: "位置情報が許可されていません。設定で許可するか、郵便番号で検索できます。")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .notDetermined, let completion = permissionCompletion {
            permissionCompletion = nil
            completion()
        }
        guard awaitingLocation else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: locate()
        case .denied, .restricted: denied()
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard awaitingLocation, let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        awaitingLocation = false
        timeout?.cancel()
        // Do not associate an old address label with a new GPS coordinate.
        model = UserAddressRegistModel()
        complete(location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard awaitingLocation else { return }
        awaitingLocation = false
        timeout?.cancel()
        isShowProgres = false
        showPopup(withMessage: "現在地を取得できませんでした。再試行するか、郵便番号で検索してください。")
    }

    func searchArea() {
        let query = areaQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isShowProgres else { return }
        geocode("日本 " + query)
    }

    func searchPostalCode() {
        guard !isShowProgres else { return }
        let code: String
        do { code = try PostalCodeLookup.normalize(postalQuery) }
        catch { showPopup(withMessage: error.localizedDescription); return }
        isShowProgres = true
        postalCandidates = []
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let addresses = try await PostalCodeLookup.addresses(for: code)
                self.isShowProgres = false
                if addresses.count == 1 {
                    self.selectPostalAddress(addresses[0])
                } else {
                    self.postalCandidates = addresses
                    self.showPostalCandidates = true
                }
            } catch {
                self.isShowProgres = false
                self.showPopup(withMessage: (error as? PostalCodeLookup.LookupError)?.errorDescription
                    ?? "住所を取得できませんでした。通信を確認して再試行してください。")
            }
        }
    }

    func selectPostalAddress(_ address: ApiAddress) {
        showPostalCandidates = false
        geocode(address.geocodingAddress, postalAddress: address)
    }

    private func geocode(_ query: String, postalAddress: ApiAddress? = nil) {
        isShowProgres = true
        let requestID = UUID()
        geocodeRequestID = requestID
        timeout?.cancel()
        timeout = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(20)) } catch { return }
            guard let self, self.geocodeRequestID == requestID else { return }
            self.geocodeRequestID = nil
            self.geocoder.cancelGeocode()
            self.isShowProgres = false
            self.showPopup(withMessage: "地域の位置を取得できませんでした。通信を確認して再試行するか、現在地から検索してください。")
        }
        geocoder.geocodeAddressString(query, in: nil, preferredLocale: Locale(identifier: "ja_JP")) { [weak self] places, error in
            DispatchQueue.main.async {
                guard let self, self.geocodeRequestID == requestID else { return }
                self.geocodeRequestID = nil
                self.timeout?.cancel()
                self.isShowProgres = false
                guard let place = places?.first, let coordinate = place.location?.coordinate else {
                    self.showPopup(withMessage: postalAddress == nil
                        ? "地域が見つかりませんでした。市区町村と町名、または郵便番号で検索してください。"
                        : "住所は見つかりましたが、地域の位置を取得できませんでした。再試行するか、現在地から検索してください。")
                    return
                }
                self.model = UserAddressRegistModel()
                self.model.postalCode = postalAddress?.zipcode ?? place.postalCode ?? ""
                self.model.administrativeArea = postalAddress?.address1 ?? place.administrativeArea ?? ""
                self.model.locality = postalAddress?.address2 ?? place.locality ?? ""
                self.model.thoroughfare = postalAddress?.address3 ?? place.thoroughfare ?? ""
                self.complete(coordinate)
            }
        }
    }

    private func complete(_ coordinate: CLLocationCoordinate2D) {
        isShowProgres = false
        guard (20...46).contains(coordinate.latitude), (122...154).contains(coordinate.longitude) else {
            showPopup(withMessage: "日本国内の地域を指定してください。")
            return
        }
        model.latitude = String(coordinate.latitude)
        model.longitude = String(coordinate.longitude)
        saveUserAddressRegistModel(model)
        UserDefaults.standard.set(false, forKey: "collection.localOnly")
        activie = true
    }
}
