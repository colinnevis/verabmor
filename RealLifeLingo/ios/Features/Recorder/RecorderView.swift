import SwiftUI

struct RecorderView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var isRecording = false
    @State private var transcript: Transcript?
    @State private var segments: [TranscriptSegment] = []
    @State private var statusMessage: String = "Tap record to begin"
    @State private var isProcessing = false
    @State private var generatedCards: [Card] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(statusMessage)
                        .font(.headline)
                    if isRecording {
                        Text("Recording…")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(segments) { segment in
                            HStack(alignment: .top) {
                                Text(segment.speaker)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(segment.text)
                                        .font(.body)
                                    if segment.isStarred {
                                        Label("Starred", systemImage: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .background(segment.isStarred ? Color.yellow.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 300)

                if isProcessing {
                    ProgressView("Processing AI cards…")
                }

                HStack(spacing: 24) {
                    Button(action: markStar) {
                        Label("Mark", systemImage: "star")
                    }
                    .disabled(!isRecording)

                    Button(action: toggleRecording) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "record.circle.fill")
                            .resizable()
                            .frame(width: 88, height: 88)
                            .foregroundColor(isRecording ? .red : .green)
                    }
                }

                if !generatedCards.isEmpty {
                    Text("Generated \(generatedCards.count) new cards!")
                        .font(.headline)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Recorder")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func toggleRecording() {
        if isRecording {
            Task { await stopRecording() }
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        do {
            try environment.transcriptionService.beginRecording()
            isRecording = true
            statusMessage = "Recording… tap star to highlight"
            segments = []
            generatedCards = []
        } catch {
            statusMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    private func markStar() {
        environment.transcriptionService.markImportant()
    }

    private func stopRecording() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let captured = try await environment.transcriptionService.endRecording()
            transcript = captured
            segments = captured.segments
            statusMessage = "Transcribed \(segments.count) sentences"
            let sourceId = UUID().uuidString
            let text = segments.map { $0.text }.joined(separator: " ")
            let language = environment.nlpService.detectLanguage(for: text) ?? appState.currentUser.l2
            let source = Source(id: sourceId, userId: appState.currentUser.id, orgId: nil, type: .transcript, uri: "recording://\(sourceId)", language: language, metaJSON: "{}", firstSeenAt: Date(), lastIngestedAt: Date())
            environment.sourceRepository.save(source)
            var updatedTranscript = captured
            updatedTranscript = Transcript(id: captured.id, sourceId: sourceId, durationSec: captured.durationSec, segments: captured.segments)
            environment.transcriptRepository.save(updatedTranscript)
            let cards = await environment.cardCreationService.generateCards(user: appState.currentUser, source: source, transcript: updatedTranscript)
            generatedCards = cards
            let event = UsageEvent(id: UUID().uuidString, userId: appState.currentUser.id, orgId: nil, type: .transcribe, createdAt: Date(), payloadJSON: "{\"duration\":\(captured.durationSec)}")
            environment.ingestionService.recordUsage(event: event)
        } catch {
            statusMessage = "Transcription failed: \(error.localizedDescription)"
        }
        isRecording = false
    }
}
