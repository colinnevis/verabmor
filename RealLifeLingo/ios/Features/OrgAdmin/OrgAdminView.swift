import SwiftUI

struct OrgAdminView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var selectedOrgId: String = ""
    @State private var usageRows: [WeeklyUsage] = []
    @State private var message: String = ""

    private var orgs: [Org] {
        environment.orgRepository.fetchAll()
    }

    var body: some View {
        List {
            Section(header: Text("Organization")) {
                Picker("Org", selection: $selectedOrgId) {
                    ForEach(orgs) { org in
                        Text(org.name).tag(org.id)
                    }
                }
                .onChange(of: selectedOrgId) { _ in loadUsage() }
            }

            Section(header: Text("Metrics")) {
                ForEach(groupedByWeek.keys.sorted(by: >), id: \.self) { week in
                    if let rows = groupedByWeek[week] {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week of \(formatted(date: week))")
                                .font(.headline)
                            Text("Active users: \(Set(rows.map { $0.userId }).count)")
                            Text("Transcripts: \(rows.map { $0.transcripts }.reduce(0, +))")
                            Text("New cards: \(rows.map { $0.newCards }.reduce(0, +))")
                            Text("Reviews: \(rows.map { $0.cardsReviewed }.reduce(0, +))")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section(header: Text("Users")) {
                ForEach(userRows, id: \.userId) { row in
                    VStack(alignment: .leading) {
                        Text(row.userId)
                        Text("Reviews/week: \(row.cardsReviewed)")
                            .font(.caption)
                        Text("Transcripts/week: \(row.transcripts)")
                            .font(.caption)
                        Text("Last activity: \(formatted(date: row.lastActivityAt))")
                            .font(.caption)
                    }
                }
            }

            Section {
                Button("Export TSV") {
                    let export = environment.analyticsService.export(type: .b2bOrgMetrics)
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("b2b_org_metrics.tsv")
                    do {
                        try export.data(using: .utf8)?.write(to: url)
                        message = "Exported to \(url.lastPathComponent)"
                    } catch {
                        message = "Export failed: \(error.localizedDescription)"
                    }
                }
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Org Admin")
        .onAppear {
            if selectedOrgId.isEmpty {
                selectedOrgId = appState.memberships.first?.orgId ?? orgs.first?.id ?? ""
            }
            loadUsage()
        }
    }

    private func loadUsage() {
        guard !selectedOrgId.isEmpty else {
            usageRows = []
            return
        }
        usageRows = environment.weeklyUsageRepository.weeklyUsage(forOrg: selectedOrgId)
    }

    private var groupedByWeek: [Date: [WeeklyUsage]] {
        Dictionary(grouping: usageRows, by: { Calendar.current.startOfDay(for: $0.weekStart) })
    }

    private var userRows: [WeeklyUsage] {
        usageRows.sorted { $0.userId < $1.userId }
    }

    private func formatted(date: Date?) -> String {
        guard let date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
