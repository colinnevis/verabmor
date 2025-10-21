import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var queue: [Card] = []
    @State private var currentIndex: Int = 0

    var body: some View {
        VStack {
            if currentIndex < queue.count {
                let card = queue[currentIndex]
                ReviewCardView(card: card)
                Spacer()
                gradeButtons(for: card)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("All reviews complete! 🎉")
                        .font(.title2)
                    Button("Refresh") { loadQueue() }
                }
            }
        }
        .padding()
        .navigationTitle("Review")
        .onAppear(perform: loadQueue)
        .onReceive(NotificationCenter.default.publisher(for: .startReviewSession)) { _ in
            loadQueue()
        }
    }

    private func gradeButtons(for card: Card) -> some View {
        HStack {
            ForEach(0..<6) { grade in
                Button(action: { submit(grade: grade, for: card) }) {
                    Text("\(grade)")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.blue.opacity(Double(grade) / 7.0 + 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.white)
            }
        }
    }

    private func submit(grade: Int, for card: Card) {
        let updated = environment.srsService.grade(card: card, grade: grade, user: appState.currentUser, device: "ios")
        queue[currentIndex] = updated
        currentIndex += 1
    }

    private func loadQueue() {
        queue = environment.srsService.dailyQueue(for: appState.currentUser)
        currentIndex = 0
    }
}

private struct ReviewCardView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: card.imageURL)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Color.gray
            }
            .frame(height: 200)
            Text(card.l2Text)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            Text(card.exampleL2)
                .font(.title3)
            Text(card.gloss)
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}
