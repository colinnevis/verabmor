import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var showImport = false
    @State private var showRecorder = false
    @State private var dueCount: Int = 0
    @State private var newCount: Int = 0

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Today's Reviews")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Due Cards")
                                .font(.headline)
                            Text("\(dueCount) cards ready for review")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Review") {
                            NotificationCenter.default.post(name: .startReviewSession, object: nil)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    HStack {
                        VStack(alignment: .leading) {
                            Text("New Cards")
                                .font(.headline)
                            Text("\(newCount) new for today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }

                Section(header: Text("Capture")) {
                    Button {
                        showRecorder = true
                    } label: {
                        Label("Record Lesson", systemImage: "mic.fill")
                    }
                    Button {
                        showImport = true
                    } label: {
                        Label("Add Source", systemImage: "tray.and.arrow.down")
                    }
                }

                Section(header: Text("Streak")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next bill: \(formatted(date: appState.currentUser.nextBillDate))")
                        ProgressView(value: min(Double(dueCount) / Double(max(appState.currentUser.goalDailyNew, 1)), 1.0)) {
                            Text("Daily goal: \(appState.currentUser.goalDailyNew)")
                        }
                    }
                }
            }
            .navigationTitle("RealLife Lingo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: PlanView()) {
                        Image(systemName: "creditcard")
                    }
                }
            }
            .sheet(isPresented: $showImport) {
                ImportView()
            }
            .sheet(isPresented: $showRecorder) {
                RecorderView()
            }
            .onAppear(perform: refreshCounts)
        }
    }

    private func refreshCounts() {
        let queue = environment.srsService.dailyQueue(for: appState.currentUser)
        dueCount = queue.filter { $0.nextDueAt != nil && ($0.nextDueAt ?? Date()) <= Date() }.count
        newCount = queue.filter { $0.nextDueAt == nil }.count
    }

    private func formatted(date: Date?) -> String {
        guard let date else { return "Not scheduled" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

extension Notification.Name {
    static let startReviewSession = Notification.Name("startReviewSession")
}
