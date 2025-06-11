import SwiftUI
import ComposableArchitecture
import FirebaseCore
import KakaoSDKCommon
import KakaoSDKAuth


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct MeokPTApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Dependency(\.modelContainer) var modelContainer
    
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    init() {
        let kakaoSDKKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_SDK_KEY") as? String ?? ""
        let kakaoSDKKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_SDK_KEY") as? String ?? ""
        KakaoSDK.initSDK(appKey: kakaoSDKKey)
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: MeokPTApp.store)
                .modelContainer(modelContainer)
                .onOpenURL { url in
                    if (AuthApi.isKakaoTalkLoginUrl(url)) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
