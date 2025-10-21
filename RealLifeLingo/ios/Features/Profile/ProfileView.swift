import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var hobbies: String = ""
    @State private var dailyGoal: Int = 20
    @State private var message: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Learner")) {
                    TextField("Display Name", text: Binding(
                        get: { appState.currentUser.displayName },
                        set: { updateName($0) }
                    ))
                    Text("Email: \(appState.currentUser.email)")
                    Stepper(value: $dailyGoal, in: 5...50, step: 5) {
                        Text("Daily new cards: \(dailyGoal)")
                    }
                    .onChange(of: dailyGoal) { _ in updateGoal() }
                }

                Section(header: Text("Preferences")) {
                    TextField("Hobbies", text: $hobbies)
                        .onSubmit(updateHobbies)
                    Button("Save Preferences", action: updateHobbies)
                }

                Section(header: Text("Plan")) {
                    NavigationLink("Plan & Billing") {
                        PlanView()
                    }
                    if !appState.memberships.isEmpty {
                        NavigationLink("Org Admin Dashboard") {
                            OrgAdminView()
                        }
                    }
                    Text("Status: \(appState.currentUser.planTier.rawValue.capitalized)")
                }

                Section(header: Text("Exports")) {
                    Button("Export Cards.tsv") { export(.cards) }
                    Button("Export Reviews.tsv") { export(.reviews) }
                    Button("Export B2B Metrics") { export(.b2bOrgMetrics) }
                    if !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                hobbies = appState.currentUser.hobbies
                dailyGoal = appState.currentUser.goalDailyNew
            }
        }
    }

    private func updateName(_ newName: String) {
        var user = appState.currentUser
        user.displayName = newName
        environment.userRepository.save(user)
        appState.currentUser = user
    }

    private func updateGoal() {
        var user = appState.currentUser
        user.goalDailyNew = dailyGoal
        environment.userRepository.save(user)
        appState.currentUser = user
    }

    private func updateHobbies() {
        var user = appState.currentUser
        user.hobbies = hobbies
        environment.userRepository.save(user)
        appState.currentUser = user
        message = "Preferences saved"
    }

    private func export(_ type: TSVExportType) {
        let content = environment.analyticsService.export(type: type)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(type.rawValue).tsv")
        do {
            try content.data(using: .utf8)?.write(to: url)
            message = "Exported to \(url.lastPathComponent)"
        } catch {
            message = "Failed to export: \(error.localizedDescription)"
        }
    }
}
