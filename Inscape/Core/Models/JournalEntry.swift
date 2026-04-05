// Core/Models/JournalEntry.swift

import Foundation
import Combine

// MARK: - Model

struct JournalEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let imageURL: String
    let question: String
    var reflectionText: String
    let date: Date
    let concept: String

    // Emotional response selections from SelectFromImagesView
    var selectedSymbol: String?     // SF symbol name  e.g. "heart.fill"
    var selectedWord: String?       // emotion word    e.g. "Hopeful"
    var selectedColorName: String?  // color id        e.g. "blue"

    init(imageURL: String,
         question: String,
         reflectionText: String,
         concept: String,
         selectedSymbol: String? = nil,
         selectedWord: String? = nil,
         selectedColorName: String? = nil) {
        self.id = UUID()
        self.imageURL = imageURL
        self.question = question
        self.reflectionText = reflectionText
        self.date = Date()
        self.concept = concept
        self.selectedSymbol   = selectedSymbol
        self.selectedWord     = selectedWord
        self.selectedColorName = selectedColorName
    }
}

// MARK: - Store

final class JournalStore: ObservableObject {
    static let shared = JournalStore()

    @Published private(set) var entries: [JournalEntry] = []

    private let key = "inscape_journal_entries"

    private init() { load() }

    func add(_ entry: JournalEntry) {
        entries.insert(entry, at: 0)
        persist()
    }

    func update(_ updated: JournalEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == updated.id }) else { return }
        entries[idx] = updated
        persist()
    }

    // MARK: - Private

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
