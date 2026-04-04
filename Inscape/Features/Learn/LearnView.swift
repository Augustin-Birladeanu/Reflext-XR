// LearnView.swift

import SwiftUI

struct LearnView: View {

    @Environment(\.dismiss) private var dismiss

    private let sections: [LearnSection] = [
        LearnSection(
            title: "Creativity",
            imageName: "learnUI-creativity",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.70, green: 0.20, blue: 0.60),
                    Color(red: 0.90, green: 0.40, blue: 0.10),
                    Color(red: 0.20, green: 0.40, blue: 0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            destination: .creativity
        ),
        LearnSection(
            title: "Emotions",
            imageName: "learnUI-emotions",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.80, green: 0.30, blue: 0.30),
                    Color(red: 0.60, green: 0.15, blue: 0.40)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            destination: .emotionsTopics
        ),
        LearnSection(
            title: "Self",
            imageName: "learnUI-self",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.50, blue: 0.60),
                    Color(red: 0.05, green: 0.35, blue: 0.50)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            destination: .selfTopics
        ),
        LearnSection(
            title: "Journey",
            imageName: "createUI-select",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.25, blue: 0.35),
                    Color(red: 0.35, green: 0.40, blue: 0.30),
                    Color(red: 0.15, green: 0.20, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            destination: nil
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Custom Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Text("Learn")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // MARK: Section Cards
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(sections) { section in
                        if let dest = section.destination {
                            NavigationLink(value: dest) {
                                LearnSectionCard(section: section)
                            }
                            .buttonStyle(.plain)
                        } else {
                            LearnSectionCard(section: section)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
        }
        .navigationDestination(for: LearnDestination.self) { dest in
            switch dest {
            case .creativity:
                CreativityView()
            case .emotionsTopics:
                EmotionsTopicsView()
            case .neuroplasticity:
                NeuroplasticityView()
            case .gratitude:
                GratitudeView()
            case .selfTopics:
                SelfTopicsView()
            case .selfCompassion:
                SelfCompassionView()
            case .selfSoothing:
                SelfSoothingView()
            case .unconsciousMind:
                UnconsciousMindView()
            case .selfActualization:
                SelfActualizationView()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Destination

enum LearnDestination: Hashable {
    case creativity
    case emotionsTopics
    case neuroplasticity
    case gratitude
    case selfTopics
    case selfCompassion
    case selfSoothing
    case unconsciousMind
    case selfActualization
}

// MARK: - Section Model

struct LearnSection: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String?
    let fallbackGradient: LinearGradient
    let destination: LearnDestination?
}

// MARK: - Section Card View

struct LearnSectionCard: View {
    let section: LearnSection

    var body: some View {
        ZStack {
            if let name = section.imageName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                section.fallbackGradient
            }

            Text(section.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}


// MARK: - Emotions Topics View

struct EmotionsTopicsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuote: String = ""

    private let quotes = [
        "\u{201C}Feelings are not forever. They visit, teach, and leave.\u{201D}",
        "\u{201C}The emotion that can break your heart is sometimes the very one that heals it.\u{201D}",
        "\u{201C}You don\u{2019}t have to control your thoughts. You just have to stop letting them control you.\u{201D}",
        "\u{201C}What we feel, we can heal.\u{201D}",
        "\u{201C}Emotion is the chief source of all becoming-conscious.\u{201D}",
        "\u{201C}In the middle of difficulty lies opportunity — and awareness.\u{201D}",
        "\u{201C}Name it to tame it.\u{201D}"
    ]

    private let topics: [(title: String, destination: LearnDestination)] = [
        ("Neuroplasticity", .neuroplasticity),
        ("Gratitude", .gratitude)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Text("Emotions")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {

                    // Hero image with quote overlay
                    ZStack {
                        if UIImage(named: "learnUI-emotions") != nil {
                            Image("learnUI-emotions")
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [Color(red: 0.80, green: 0.30, blue: 0.30), Color(red: 0.60, green: 0.15, blue: 0.40)],
                                startPoint: .top, endPoint: .bottom
                            )
                        }
                        Color.black.opacity(0.35)
                        Text(currentQuote)
                            .font(.system(size: 20, weight: .bold))
                            .italic()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                            .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Topic buttons
                    ForEach(topics, id: \.title) { topic in
                        NavigationLink(value: topic.destination) {
                            Text(topic.title)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
        .onAppear { currentQuote = quotes.randomElement() ?? "" }
    }
}

// MARK: - Self Topics View

struct SelfTopicsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuote: String = ""

    private let quotes = [
        "\u{201C}Knowing yourself is the beginning of all wisdom.\u{201D}",
        "\u{201C}To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment.\u{201D}",
        "\u{201C}The most courageous act is still to think for yourself. Aloud.\u{201D}",
        "\u{201C}You yourself, as much as anybody in the entire universe, deserve your love and affection.\u{201D}",
        "\u{201C}Owning our story and loving ourselves through that process is the bravest thing we will ever do.\u{201D}",
        "\u{201C}The privilege of a lifetime is to become who you truly are.\u{201D}",
        "\u{201C}What lies behind us and what lies before us are tiny matters compared to what lies within us.\u{201D}"
    ]

    private let topics: [(title: String, destination: LearnDestination)] = [
        ("Self-Compassion", .selfCompassion),
        ("Self-Soothing", .selfSoothing),
        ("The Unconscious Mind", .unconsciousMind),
        ("Self-Actualization", .selfActualization)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Text("Self")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {

                    // Hero image with quote overlay
                    ZStack {
                        if UIImage(named: "learnUI-self") != nil {
                            Image("learnUI-self")
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [Color(red: 0.10, green: 0.50, blue: 0.60), Color(red: 0.05, green: 0.35, blue: 0.50)],
                                startPoint: .top, endPoint: .bottom
                            )
                        }
                        Color.black.opacity(0.35)
                        Text(currentQuote)
                            .font(.system(size: 20, weight: .bold))
                            .italic()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                            .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Topic buttons
                    ForEach(topics, id: \.title) { topic in
                        NavigationLink(value: topic.destination) {
                            Text(topic.title)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
        .onAppear { currentQuote = quotes.randomElement() ?? "" }
    }
}

#Preview {
    NavigationStack {
        LearnView()
    }
}
