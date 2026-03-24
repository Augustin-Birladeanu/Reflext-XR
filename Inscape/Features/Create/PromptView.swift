// PromptView.swift

import SwiftUI

struct PromptView: View {
    let concept: String
    var dailyConcept: DailyCreationConcept? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var navManager: NavigationManager

    @State private var selectedEmotion: String? = nil
    @State private var selectedStyle: String? = nil
    @State private var navigateToResult = false
    @State private var reflectionText: String = ""

    private let emotions = [
        "Joy", "Sadness", "Anxiety", "Hope", "Fear", "Anger",
        "Love", "Grief", "Calm", "Confusion", "Loneliness", "Pride",
        "Gratitude", "Shame", "Peace", "Overwhelm", "Curiosity",
        "Numbness", "Tenderness", "Courage"
    ]

    private let styles = [
        "Watercolor", "Oil Painting", "Sketch", "Pastel",
        "Dreamlike", "Abstract", "Minimalist", "Surrealist",
        "Ink", "Vintage", "Impressionist"
    ]

    // Short subtitle shown under the "Prompt" title
    private var conceptSubtitle: String {
        if let dc = dailyConcept { return dc.reflection }
        switch concept {
        case "A Safe Space":      return "A safe space for emotions"
        case "Emotional Waves":   return "Riding waves of feeling"
        case "Resilience":        return "Finding strength within"
        case "Journey":           return "Walking your own path"
        case "Masks we wear":     return "The faces we show the world"
        case "Crossroads":        return "Choosing your direction"
        case "Future Self":       return "Envisioning who you'll become"
        case "Bridges":           return "Connecting what was with what is"
        case "Friendship":        return "The bonds that hold us"
        case "Growing Roots":     return "Grounding yourself in the present"
        case "Letting Go":        return "Releasing what no longer serves"
        case "Garden of peace":   return "Cultivating inner stillness"
        case "Rising from Ashes": return "Rebirth through transformation"
        case "Inner Child":       return "Reconnecting with your younger self"
        default:                  return "Exploring your inner world"
        }
    }

    // Sentence split around the emotion blank: before + [emotion] + after
    private var template: (before: String, after: String) {
        switch concept {
        case "A Safe Space":
            return ("Design a safe container where", "can rest without judgment.")
        case "Emotional Waves":
            return ("A wave of", "rises and falls across a vast open sea.")
        case "Resilience":
            return ("A figure made of", "stands unbroken in the heart of the storm.")
        case "Journey":
            return ("A traveller carrying", "walks a winding road into the horizon.")
        case "Masks we wear":
            return ("Behind every mask,", "hides, waiting to be seen.")
        case "Crossroads":
            return ("At the crossroads, a sign points toward", "lighting the path ahead.")
        case "Future Self":
            return ("A future self radiating", "stands at the edge of a new dawn.")
        case "Bridges":
            return ("A bridge built from", "stretches across a vast, open divide.")
        case "Friendship":
            return ("Two figures share the warmth of", "beneath a starlit sky.")
        case "Growing Roots":
            return ("Roots grow deeper, nourished by", ", reaching upward toward the light.")
        case "Letting Go":
            return ("A hand gently releases", "into the open, boundless sky.")
        case "Garden of peace":
            return ("A garden blooms with", "growing softly between every petal.")
        case "Rising from Ashes":
            return ("From the ashes,", "takes flight on brilliant new wings.")
        case "Inner Child":
            return ("My inner child longs to feel", "and be free once more.")
        default:
            return ("An image filled with", "spreads across the canvas.")
        }
    }

    private var canProceed: Bool {
        dailyConcept != nil ? selectedStyle != nil : (selectedEmotion != nil && selectedStyle != nil)
    }

   private static let styleDescriptions: [String: String] = [
    "Watercolor":    "soft watercolor washes, delicate brushstrokes, translucent layers, flowing pigment on textured paper",
    "Oil Painting":  "rich oil paint texture, impasto technique, deep luminous colors, classical brushwork",
    "Sketch":        "detailed pencil sketch, fine linework, subtle hatching, raw expressive strokes",
    "Pastel":        "soft pastel tones, chalky texture, gentle blending, warm muted palette",
    "Dreamlike":     "ethereal lighting, soft focus, cinematic bokeh, surreal atmosphere, hazy golden tones",
    "Abstract":      "bold abstract forms, expressive color fields, dynamic composition, non-representational shapes",
    "Minimalist":    "clean minimalist composition, generous negative space, simple geometric forms, muted palette",
    "Surrealist":    "surrealist imagery, unexpected juxtapositions, dreamscape environment, hyper-detailed realism",
    "Ink":           "bold ink illustration, strong contrast, fluid brushwork, expressive black linework",
    "Vintage":       "vintage aesthetic, faded tones, aged texture, nostalgic color grading, retro grain",
    "Impressionist": "impressionist style, loose visible brushstrokes, vibrant dappled light, atmospheric color"
]

private var composedPrompt: String {
    let style            = selectedStyle ?? ""
    let styleDescription = Self.styleDescriptions[style] ?? "\(style) art style"
    if let dc = dailyConcept {
        let reflection = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let reflectionClause = reflection.isEmpty ? "" : " Personal reflection: \(reflection)."
        return "\(dc.prompt)\(reflectionClause) Rendered in \(styleDescription). Theme: \(dc.name)."
    }
    let emotion = selectedEmotion?.lowercased() ?? ""
    let t       = template
    return "\(t.before) \(emotion) \(t.after) Rendered in \(styleDescription). Theme: \(concept)."
}

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Button {} label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 42, height: 42)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(.separator), lineWidth: 1.5))
                    }
                }
                .padding(.bottom, 10)

                Text("Prompt")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text(conceptSubtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .background(Color(.systemBackground))

            // MARK: Content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    if let dc = dailyConcept {
                        // Daily creation card
                        VStack(alignment: .leading, spacing: 20) {
                            Text(dc.prompt)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Reflect")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Text(dc.reflection)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                ZStack(alignment: .topLeading) {
                                    if reflectionText.isEmpty {
                                        Text("Write your thoughts here…")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(.placeholderText))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                    }
                                    TextEditor(text: $reflectionText)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                        .frame(minHeight: 80)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                    } else {
                        // Standard sentence card
                        VStack(alignment: .leading, spacing: 60) {
                            Text(template.before)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)

                            pickerCapsule(
                                label: selectedEmotion ?? "Pick an Emotion",
                                isEmpty: selectedEmotion == nil,
                                options: emotions
                            ) { selectedEmotion = $0 }

                            Text(template.after)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, minHeight: 340, alignment: .leading)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                    }

                    // Style picker
                    pickerCapsule(
                        label: selectedStyle ?? "Pick a Style",
                        isEmpty: selectedStyle == nil,
                        options: styles
                    ) { selectedStyle = $0 }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
        }
        .safeAreaInset(edge: .bottom) {
            Button { navigateToResult = true } label: {
                Text("Next")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canProceed ? Color.blue : Color.blue.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canProceed)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .animation(.easeInOut(duration: 0.2), value: canProceed)
        }
        .navigationBarHidden(true)
        .onChange(of: navManager.popToRoot) { _, popping in
            if popping { dismiss() }
        }
        .navigationDestination(isPresented: $navigateToResult) {
            PromptEditView(concept: concept, subtitle: conceptSubtitle, prompt: composedPrompt)
        }
    }

    // MARK: - Reusable capsule picker

    @ViewBuilder
    private func pickerCapsule(
        label: String,
        isEmpty: Bool,
        options: [String],
        strokeColor: Color = .blue,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { onSelect(option) }
            }
        } label: {
            HStack(spacing: 0) {
                Spacer()
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(strokeColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color(.systemBackground))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(strokeColor, lineWidth: 1.5))
        }
    }
}

#Preview {
    NavigationStack {
        PromptView(concept: "A Safe Space")
            .environmentObject(SessionManager.shared)
    }
}
