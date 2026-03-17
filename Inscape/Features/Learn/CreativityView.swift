// CreativityView.swift

import SwiftUI

struct CreativityView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var currentQuote: String = ""

    private let quotes = [
        "\u{201C}Creativity is intelligence having fun.\u{201D}",
        "\u{201C}You can\u{2019}t use up creativity. The more you use, the more you have.\u{201D}",
        "\u{201C}Creativity takes courage.\u{201D}",
        "\u{201C}The creative adult is the child who survived.\u{201D}",
        "\u{201C}Imagination is the beginning of creation.\u{201D}",
        "\u{201C}Every artist was first an amateur.\u{201D}",
        "\u{201C}Creativity is connecting things others don\u{2019}t see as connected.\u{201D}",
        "\u{201C}The worst enemy to creativity is self-doubt.\u{201D}",
        "\u{201C}Create with the heart; build with the mind.\u{201D}",
        "\u{201C}An idea that is not dangerous is unworthy of being called an idea at all.\u{201D}",
        "\u{201C}Creativity involves breaking out of established patterns in order to look at things differently.\u{201D}",
        "\u{201C}You can never solve a problem on the level on which it was created.\u{201D}",
        "\u{201C}The desire to create is one of the deepest yearnings of the human soul.\u{201D}",
        "\u{201C}Creativity is not a talent. It is a way of operating.\u{201D}",
        "\u{201C}Do not fear mistakes. There are none.\u{201D}",
        "\u{201C}Art enables us to find ourselves and lose ourselves at the same time.\u{201D}",
        "\u{201C}Creativity is the power to connect the seemingly unconnected.\u{201D}",
        "\u{201C}The creative process is a process of surrender, not control.\u{201D}"
    ]

    private let topics = [
        "Creative Journaling",
        "Creative Calm",
        "Flow State",
        "Gratitude",
        "Awe & Wonder",
        "Default Mode Network",
        "Harnessing the Muse"
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
                Text("Creativity")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // MARK: Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {

                    // Hero image card with random quote overlay
                    ZStack {
                        if UIImage(named: "learnUI-creativity") != nil {
                            Image("learnUI-creativity")
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.70, green: 0.20, blue: 0.60),
                                    Color(red: 0.90, green: 0.40, blue: 0.10),
                                    Color(red: 0.20, green: 0.40, blue: 0.80)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }

                        // Scrim for legibility
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
                    ForEach(topics, id: \.self) { topic in
                        Button {
                            // TODO: navigate into topic
                        } label: {
                            Text(topic)
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
        .onAppear {
            currentQuote = quotes.randomElement() ?? ""
        }
    }
}

#Preview {
    NavigationStack {
        CreativityView()
    }
}
