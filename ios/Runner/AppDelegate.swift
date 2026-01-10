import UIKit
import Flutter
import NidThirdPartyLogin

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Naver (Nid) OAuth redirect handling
    if NidOAuth.shared.handleURL(url) {
      return true
    }

    // Let Flutter plugins / other handlers process the URL
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    // ✅ Scene 환경에서도 안전하게 messenger 확보
    if let registrar = self.registrar(forPlugin: "app.config") {
      let channel = FlutterMethodChannel(
        name: "app.config",
        binaryMessenger: registrar.messenger()
      )

      channel.setMethodCallHandler { call, result in
        if call.method == "getKakaoNativeKey" {
          let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String
          result(key)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}