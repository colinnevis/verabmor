import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var card: Card
    @State private var isStarred: Bool

    init(card: Card) {
        _card = State(initialValue: card)
        _isStarred = State(initialValue: card.tags.contains("starred"))
    }

    var body: some View {
        Form {
            Section {
                AsyncImage(url: URL(string: card.imageURL)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color.gray
                }
                .frame(height: 200)
                TextField("L2", text: $card.l2Text)
                TextField("Gloss", text: $card.gloss)
                TextField("Example (L2)", text: $card.exampleL2)
                TextField("Example (L1)", text: $card.exampleL1)
                TextField("Tags", text: Binding(
                    get: { card.tags.joined(separator: ",") },
                    set: { card.tags = $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
                ))
                Toggle("Pinned", isOn: $isStarred)
            }

            Section(header: Text("Metadata")) {
                Text("Source: \(card.sourceType?.rawValue ?? "")")
                Text("CEFR: \(card.cefr)")
                Text("Next due: \(formatted(date: card.nextDueAt))")
                Text("Ease: \(String(format: "%.2f", card.ease))")
            }
        }
        .navigationTitle(card.l2Text)
        .onDisappear(perform: save)
    }

    private func save() {
        if isStarred && !card.tags.contains("starred") {
            card.tags.append("starred")
        } else if !isStarred {
            card.tags.removeAll { $0 == "starred" }
        }
        environment.cardRepository.save(card)
    }

    private func formatted(date: Date?) -> String {
        guard let date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
