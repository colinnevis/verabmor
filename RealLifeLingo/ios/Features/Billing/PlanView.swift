import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var autoReactivate: Bool = true
    @State private var cloudAIEnabled: Bool = true

    var body: some View {
        Form {
            Section(header: Text("Current Plan")) {
                Text("Tier: \(appState.currentUser.planTier.rawValue.capitalized)")
                Text("Next bill: \(formatted(date: appState.currentUser.nextBillDate))")
                Text("Last usage: \(formatted(date: appState.currentUser.lastUsageAt))")
            }

            Section(header: Text("Preferences")) {
                Toggle("Auto Reactivate AI", isOn: $autoReactivate)
                    .onChange(of: autoReactivate) { _ in updateUser() }
                Toggle("Allow Cloud AI", isOn: $cloudAIEnabled)
                    .onChange(of: cloudAIEnabled) { _ in updateUser() }
            }

            Section(header: Text("Actions")) {
                Button("Go Storage Mode") {
                    updatePlan(to: .storage)
                }
                Button("Reactivate") {
                    updatePlan(to: .active)
                }
            }
        }
        .navigationTitle("Plan & Billing")
        .onAppear {
            autoReactivate = appState.currentUser.autoReactivate
            cloudAIEnabled = appState.currentUser.cloudAIEnabled
        }
    }

    private func updatePlan(to tier: PlanTier) {
        var user = appState.currentUser
        user.planTier = tier
        user.lastStateChangeAt = Date()
        environment.userRepository.save(user)
        appState.currentUser = user
    }

    private func updateUser() {
        var user = appState.currentUser
        user.autoReactivate = autoReactivate
        user.cloudAIEnabled = cloudAIEnabled
        environment.userRepository.save(user)
        appState.currentUser = user
    }

    private func formatted(date: Date?) -> String {
        guard let date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
