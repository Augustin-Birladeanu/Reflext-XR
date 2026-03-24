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
            destination: nil
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
            destination: .selfCompassion
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
            case .selfCompassion:
                SelfCompassionView()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Destination

enum LearnDestination: Hashable {
    case creativity
    case selfCompassion
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

#Preview {
    NavigationStack {
        LearnView()
    }
}
