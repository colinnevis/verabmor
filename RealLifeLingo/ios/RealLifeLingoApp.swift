import SwiftUI

@main
struct RealLifeLingoApp: App {
    @StateObject private var environment: AppEnvironment
    @StateObject private var appState: AppState

    init() {
        let environment = AppEnvironment()
        _environment = StateObject(wrappedValue: environment)
        _appState = StateObject(wrappedValue: AppState(environment: environment))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(environment)
                .environmentObject(appState)
        }
    }
}
