import SwiftUI

/// Host app for screenshotting the nine Liquid Glass example screens.
/// Pick a screen at launch: `simctl launch <udid> <bundle> -screen 4`
/// (NSUserDefaults picks up `-key value` launch arguments automatically.)
@main
struct GalleryApp: App {
    var body: some Scene {
        WindowGroup {
            ScreenHost()
        }
    }
}

struct ScreenHost: View {
    private var index: Int {
        let n = UserDefaults.standard.integer(forKey: "screen")
        return n == 0 ? 1 : n
    }

    var body: some View {
        switch index {
        case 1: SettingsScreen()
        case 2: MusicPlayerScreen()
        case 3: OnboardingFlow()
        case 4: PhotoDetailScreen()
        case 5: DashboardScreen()
        case 6: ChatScreen()
        case 7: ProfileScreen()
        case 8: LoginScreen()
        case 9: HealthAppShell()
        default: SettingsScreen()
        }
    }
}
