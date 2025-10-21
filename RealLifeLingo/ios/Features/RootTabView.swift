import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
            CardsView()
                .tabItem {
                    Label("Cards", systemImage: "rectangle.stack")
                }
            ReviewView()
                .tabItem {
                    Label("Review", systemImage: "checkmark.circle")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .accentColor(.blue)
        .onAppear {
            environment.analyticsService.nightlyRollup()
            environment.billingService.nightlyDowngrade()
        }
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        let env = AppEnvironment(persistence: PersistenceController(inMemory: true))
        RootTabView()
            .environmentObject(env)
            .environmentObject(AppState(environment: env))
    }
}
