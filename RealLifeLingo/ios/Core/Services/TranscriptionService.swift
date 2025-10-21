import Foundation
import AVFoundation
import Speech

public protocol TranscriptionService {
    func beginRecording() throws
    func markImportant()
    func endRecording() async throws -> Transcript
    func transcribe(audioURL: URL, starredTimestamps: [TimeInterval]) async throws -> Transcript
}

public enum TranscriptionError: Error {
    case permissionDenied
    case recognizerUnavailable
    case noRecording
    case transcriptionFailed
}

public final class AppleSpeechTranscriptionService: NSObject, TranscriptionService {
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var starredTimestamps: [TimeInterval] = []
    private var currentFileURL: URL?
    private let nlpService: NLPService

    public init(nlpService: NLPService) {
        self.nlpService = nlpService
        super.init()
    }

    public func beginRecording() throws {
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lesson_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        currentFileURL = url
        starredTimestamps = []
    }

    public func markImportant() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()
        starredTimestamps.append(recorder.currentTime)
    }

    public func endRecording() async throws -> Transcript {
        guard let recorder = audioRecorder, let url = currentFileURL else { throw TranscriptionError.noRecording }
        recorder.stop()
        audioRecorder = nil
        try audioSession.setActive(false)
        return try await transcribe(audioURL: url, starredTimestamps: starredTimestamps)
    }

    public func transcribe(audioURL: URL, starredTimestamps: [TimeInterval]) async throws -> Transcript {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .notDetermined {
            try await requestPermission()
        } else if status != .authorized {
            throw TranscriptionError.permissionDenied
        }
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.requiresOnDeviceRecognition = true
        let localeCode = recognizer.locale.identifier
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = result, result.isFinal else { return }
                let transcript = self.makeTranscript(from: result.bestTranscription, languageCode: localeCode, starred: starredTimestamps)
                continuation.resume(returning: transcript)
            }
        }
    }

    private func requestPermission() async throws {
        try await withCheckedThrowingContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    continuation.resume()
                default:
                    continuation.resume(throwing: TranscriptionError.permissionDenied)
                }
            }
        }
    }

    private func makeTranscript(from transcription: SFSpeechTranscription, languageCode: String, starred: [TimeInterval]) -> Transcript {
        let sentences = nlpService.sentences(in: transcription.formattedString, language: languageCode)
        let diarized = diarize(sentences: sentences)
        var segments: [TranscriptSegment] = []
        for (index, sentence) in sentences.enumerated() {
            let segmentSpeaker = diarized[safe: index] ?? "Teacher"
            let speechSegment = transcription.segments[safe: index]
            let start = speechSegment?.timestamp ?? Double(index) * 3.0
            let duration = speechSegment?.duration ?? max(3.0, Double(sentence.count) / 12.0)
            let end = start + duration
            let isStarred = starred.contains { abs($0 - start) < 5 }
            segments.append(TranscriptSegment(id: UUID(), speaker: segmentSpeaker, text: sentence, start: start, end: end, isStarred: isStarred))
        }
        let totalDuration = segments.last?.end ?? 0
        return Transcript(id: UUID().uuidString, sourceId: UUID().uuidString, durationSec: totalDuration, segments: segments)
    }

    private func diarize(sentences: [String]) -> [String] {
        var result: [String] = []
        var currentSpeaker = "Teacher"
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("?") {
                currentSpeaker = "Teacher"
            } else if trimmed.count < 40 {
                currentSpeaker = "You"
            }
            result.append(currentSpeaker)
            currentSpeaker = currentSpeaker == "Teacher" ? "You" : "Teacher"
        }
        return result
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
