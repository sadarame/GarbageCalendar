import SwiftUI
import UIKit
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency
import FirebaseAnalytics

/// Starts advertising only after the current session's consent flow has completed.
@MainActor
final class AdvertisingConsent: ObservableObject {
    static let shared = AdvertisingConsent()
    @Published private(set) var canShowAds = false
    @Published private(set) var privacyOptionsRequired = false
    @Published private(set) var isBusy = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var adGeneration = 0
    private var completed = false
    private var sdkStarted = false

    static var presenter: UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              var controller = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
        while let presented = controller.presentedViewController { controller = presented }
        return controller
    }

    func gather() {
        guard !completed, !isBusy, UIApplication.shared.applicationState == .active,
              let controller = Self.presenter else { return }
        isBusy = true
        errorMessage = nil
        ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { [weak self] error in
            Task { @MainActor in
            guard let self else { return }
            self.privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
            if error != nil {
                self.finish(error: "広告の設定を確認できませんでした。通信を確認して再試行してください。")
                return
            }
            ConsentForm.loadAndPresentIfRequired(from: controller) { [weak self] error in
                Task { @MainActor in
                guard let self else { return }
                if error != nil {
                    self.finish(error: "広告の同意画面を表示できませんでした。あとで再試行してください。")
                } else {
                    self.requestTrackingIfNeeded()
                }
                }
            }
            }
        }
    }

    private func requestTrackingIfNeeded() {
        guard ConsentInformation.shared.canRequestAds else { finish(error: nil); return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { finish(error: nil); return }
        // Wait for the consent form dismissal before presenting Apple's system prompt.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard UIApplication.shared.applicationState == .active else {
                isBusy = false
                return
            }
            ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                Task { @MainActor in self?.finish(error: nil) }
            }
        }
    }

    private func finish(error: String?) {
        isBusy = false
        errorMessage = error
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        // Fail closed on errors, even if a previous session's consent was cached.
        completed = error == nil
        guard error == nil, ConsentInformation.shared.canRequestAds else {
            canShowAds = false
            return
        }
        if !sdkStarted {
            sdkStarted = true
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
        adGeneration += 1
        canShowAds = true
    }

    func showPrivacyOptions() {
        guard !isBusy, let controller = Self.presenter else { return }
        isBusy = true
        canShowAds = false
        ConsentForm.presentPrivacyOptionsForm(from: controller) { [weak self] error in
            Task { @MainActor in
                self?.finish(error: error == nil ? nil : "広告の設定を開けませんでした。あとで再試行してください。")
            }
        }
    }
}

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var consent = AdvertisingConsent.shared
    @AppStorage("privacy.analyticsEnabled") private var analyticsEnabled = false
    @AppStorage("privacy.explained") private var explained = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("広告の表示により、無料でご利用いただけます。必要な地域では、続けて広告の同意画面を表示します。追跡を許可しなくてもアプリを利用できます。")
                    if consent.privacyOptionsRequired {
                        Button("広告のプライバシー設定") { consent.showPrivacyOptions() }
                            .disabled(consent.isBusy)
                    }
                    if let error = consent.errorMessage {
                        Text(error).font(.footnote).foregroundStyle(.secondary)
                        Button("広告の設定を再確認") { consent.gather() }.disabled(consent.isBusy)
                    }
                } header: { Text("広告") }
                Section {
                    Toggle("利用状況の分析に協力する", isOn: $analyticsEnabled)
                        .onChange(of: analyticsEnabled) { enabled in
                            Analytics.setAnalyticsCollectionEnabled(enabled)
                        }
                } header: { Text("任意の利用状況分析") }
                  footer: { Text("オンにすると、アプリの操作・端末情報・おおよその地域などをGoogle Analyticsへ送信し、改善に利用します。初期設定はオフです。いつでも変更できます。") }
                Section {
                    Link("プライバシーポリシー", destination: URL(string: "https://garbagecalendar-app.web.app/privacy/")!)
                }
            }
            .navigationTitle("プライバシー設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { explained = true; dismiss() }
                }
            }
        }
        .interactiveDismissDisabled(!explained)
    }
}

struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
#if DEBUG
        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
#else
        banner.adUnitID = "ca-app-pub-5529798279445729/9711244261"
#endif
        banner.rootViewController = AdvertisingConsent.presenter
        guard AdvertisingConsent.shared.canShowAds,
              ConsentInformation.shared.canRequestAds else { return banner }
        let request = GADRequest()
        if ATTrackingManager.trackingAuthorizationStatus != .authorized {
            let extras = GADExtras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }
        banner.load(request)
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
