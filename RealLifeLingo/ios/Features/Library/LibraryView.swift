import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var sources: [Source] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(sources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(label(for: source))
                            .font(.headline)
                        Text(source.uri)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("Last ingested: \(formatted(date: source.lastIngestedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Sources")
            .onAppear(perform: loadSources)
            .refreshable { loadSources() }
        }
    }

    private func loadSources() {
        sources = environment.sourceRepository.sources(for: appState.currentUser.id)
    }

    private func label(for source: Source) -> String {
        switch source.type {
        case .kindle: return "Kindle Highlight"
        case .transcript: return "Lesson Transcript"
        case .subtitle: return "Subtitle File"
        }
    }

    private func formatted(date: Date?) -> String {
        guard let date else { return "Never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
