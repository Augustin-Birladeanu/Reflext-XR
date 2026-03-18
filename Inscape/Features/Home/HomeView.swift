// HomeView.swift

import SwiftUI

struct HomeView: View {

    @State private var showMenu = false

    private let cards: [HomeCard] = [
        HomeCard(
            title: "Create",
            imageName: "home_create",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.45, blue: 0.20),
                    Color(red: 0.60, green: 0.25, blue: 0.65),
                    Color(red: 0.25, green: 0.55, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            destination: .create
        ),
        HomeCard(
            title: "Learn",
            imageName: "home_learn",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.65, blue: 0.85),
                    Color(red: 0.20, green: 0.40, blue: 0.70),
                    Color(red: 0.55, green: 0.75, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            destination: .learn
        ),
        HomeCard(
            title: "Reflect",
            imageName: "home_reflect",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.70, blue: 0.20),
                    Color(red: 0.90, green: 0.45, blue: 0.15),
                    Color(red: 0.65, green: 0.35, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            destination: nil
        ),
        HomeCard(
            title: "Creative Calm",
            imageName: "home_calm",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.70, blue: 0.90),
                    Color(red: 0.60, green: 0.80, blue: 0.95),
                    Color(red: 0.90, green: 0.75, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            destination: .creativeCalm
        )
    ]

    var body: some View {
        NavigationStack {
        VStack(spacing: 0) {
            // MARK: Header
            HStack(alignment: .center) {
                // Logo
                HStack(spacing: 4) {
                    Image("home_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reflect XR")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Enhancing Life for Wellness")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Hamburger menu
                Button {
                    showMenu.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))

            // MARK: Cards
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(cards) { card in
                        if let dest = card.destination {
                            NavigationLink(value: dest) {
                                HomeCardView(card: card)
                            }
                            .buttonStyle(.plain)
                        } else {
                            HomeCardView(card: card)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
        }
        .navigationDestination(for: HomeDestination.self) { dest in
            switch dest {
            case .create:
                ConceptsView()
            case .learn:
                LearnView()
            case .creativeCalm:
                CreativeCalmView()
            }
        }
        }
    }
}

// MARK: - Card Model

enum HomeDestination: Hashable {
    case create
    case learn
    case creativeCalm
}

struct HomeCard: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let fallbackGradient: LinearGradient
    let destination: HomeDestination?
}

// MARK: - Card View

struct HomeCardView: View {
    let card: HomeCard

    var body: some View {
        ZStack {
            // Try named image asset, fall back to gradient
            if UIImage(named: card.imageName) != nil {
                Image(card.imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                card.fallbackGradient
            }

            Text(card.title)
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
    HomeView()
}
