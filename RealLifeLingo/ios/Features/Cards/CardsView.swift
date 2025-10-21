import SwiftUI

struct CardsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var query: String = ""
    @State private var cards: [Card] = []
    @State private var selectedTag: String?
    @State private var selectedCEFR: String = "All"

    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                List {
                    ForEach(filteredCards) { card in
                        NavigationLink(destination: CardDetailView(card: card)) {
                            CardRow(card: card)
                        }
                    }
                }
            }
            .navigationTitle("Cards")
            .onAppear(perform: loadCards)
            .onChange(of: query) { _ in loadCards() }
        }
    }

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            HStack {
                Menu {
                    Button("All") { selectedTag = nil; loadCards() }
                    ForEach(allTags, id: \.self) { tag in
                        Button(tag) { selectedTag = tag; loadCards() }
                    }
                } label: {
                    Label(selectedTag ?? "All Tags", systemImage: "tag")
                }
                Picker("CEFR", selection: $selectedCEFR) {
                    Text("All").tag("All")
                    ForEach(["A1", "A2", "B1", "B2", "C1", "C2"], id: \.self) { cefr in
                        Text(cefr).tag(cefr)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)
        }
    }

    private var filteredCards: [Card] {
        cards.filter { card in
            let matchesQuery = query.isEmpty || card.l2Text.localizedCaseInsensitiveContains(query) || card.gloss.localizedCaseInsensitiveContains(query)
            let matchesTag = selectedTag.map { card.tags.contains($0) } ?? true
            let matchesCEFR = selectedCEFR == "All" || card.cefr == selectedCEFR
            return matchesQuery && matchesTag && matchesCEFR
        }
    }

    private var allTags: [String] {
        Array(Set(cards.flatMap { $0.tags })).sorted()
    }

    private func loadCards() {
        cards = environment.cardRepository.search(userId: appState.currentUser.id, query: query.isEmpty ? nil : query, tags: selectedTag.map { [$0] } ?? [])
    }
}

struct CardRow: View {
    let card: Card

    var body: some View {
        HStack(alignment: .top) {
            AsyncImage(url: URL(string: card.imageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(card.l2Text)
                    .font(.headline)
                Text(card.gloss)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Text(card.cefr)
                        .font(.caption)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    ForEach(card.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }
}
