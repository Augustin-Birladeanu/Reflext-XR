// EmotionalResponse.swift

import SwiftUI

// MARK: - Session (persists selections across the navigation stack)

final class EmotionalSession {
    static let shared = EmotionalSession()
    private init() {}

    var selectedSymbol: String?     // SF symbol name
    var selectedWord: String?       // emotion word
    var selectedColorName: String?  // color identifier

    func clear() {
        selectedSymbol   = nil
        selectedWord     = nil
        selectedColorName = nil
    }
}

// MARK: - Emotion colors

struct EmotionColor: Identifiable {
    let id: String      // used as the stable name stored in JournalEntry
    let color: Color

    static let all: [EmotionColor] = [
        EmotionColor(id: "blue",   color: Color(red: 0.53, green: 0.73, blue: 0.93)),
        EmotionColor(id: "purple", color: Color(red: 0.65, green: 0.48, blue: 0.88)),
        EmotionColor(id: "green",  color: Color(red: 0.42, green: 0.75, blue: 0.55)),
        EmotionColor(id: "orange", color: Color(red: 0.95, green: 0.65, blue: 0.35)),
        EmotionColor(id: "pink",   color: Color(red: 0.95, green: 0.60, blue: 0.75)),
        EmotionColor(id: "teal",   color: Color(red: 0.28, green: 0.73, blue: 0.72)),
        EmotionColor(id: "yellow",  color: Color(red: 0.97, green: 0.85, blue: 0.32)),
        EmotionColor(id: "red",     color: Color(red: 0.88, green: 0.35, blue: 0.35)),
        EmotionColor(id: "indigo",  color: Color(red: 0.37, green: 0.38, blue: 0.82)),
        EmotionColor(id: "coral",   color: Color(red: 0.98, green: 0.50, blue: 0.45)),
        EmotionColor(id: "mint",    color: Color(red: 0.60, green: 0.92, blue: 0.78)),
        EmotionColor(id: "brown",   color: Color(red: 0.67, green: 0.48, blue: 0.34)),
    ]

    static func color(for id: String) -> Color? {
        all.first(where: { $0.id == id })?.color
    }
}
