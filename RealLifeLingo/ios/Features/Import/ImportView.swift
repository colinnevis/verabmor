import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    enum ImportCategory {
        case kindle
        case readwiseCSV
        case readwiseJSON
        case subtitle
    }

    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var showImporter = false
    @State private var category: ImportCategory = .kindle
    @State private var status: String = ""
    @State private var createdCards: Int = 0

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Kindle")) {
                    Button("Import My Clippings.txt") {
                        category = .kindle
                        showImporter = true
                    }
                }
                Section(header: Text("Readwise")) {
                    Button("Import CSV") {
                        category = .readwiseCSV
                        showImporter = true
                    }
                    Button("Import JSON") {
                        category = .readwiseJSON
                        showImporter = true
                    }
                }
                Section(header: Text("Subtitles")) {
                    Button("Import SRT/VTT") {
                        category = .subtitle
                        showImporter = true
                    }
                }
                if createdCards > 0 {
                    Section(header: Text("Results")) {
                        Text("Created \(createdCards) cards")
                        Text(status)
                    }
                }
            }
            .navigationTitle("Import Sources")
            .fileImporter(isPresented: $showImporter, allowedContentTypes: allowedTypes(for: category)) { result in
                switch result {
                case .success(let url):
                    Task { await handleImport(url: url) }
                case .failure(let error):
                    status = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func allowedTypes(for category: ImportCategory) -> [UTType] {
        switch category {
        case .kindle: return [.plainText]
        case .readwiseCSV: return [.commaSeparatedText]
        case .readwiseJSON: return [.json]
        case .subtitle:
            let srt = UTType(filenameExtension: "srt") ?? .plainText
            let vtt = UTType(filenameExtension: "vtt") ?? .plainText
            return [srt, vtt]
        }
    }

    private func handleImport(url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let result: IngestionResult?
            switch category {
            case .kindle:
                result = await environment.ingestionService.importKindle(data: data, user: appState.currentUser)
            case .readwiseCSV:
                result = await environment.ingestionService.importReadwiseCSV(data: data, user: appState.currentUser)
            case .readwiseJSON:
                result = await environment.ingestionService.importReadwiseJSON(data: data, user: appState.currentUser)
            case .subtitle:
                result = await environment.ingestionService.importSubtitles(data: data, fileExtension: url.pathExtension, user: appState.currentUser)
            }
            if let result {
                createdCards = result.cards.count
                status = "Imported source \(result.source.id)"
            } else {
                createdCards = 0
                status = "No content detected"
            }
        } catch {
            status = "Failed to read file: \(error.localizedDescription)"
        }
    }
}
