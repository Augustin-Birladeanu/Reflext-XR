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
            )
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
            )
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
            )
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
            )
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            HStack(alignment: .center) {
                // Logo
                HStack(spacing: 10) {
                    ReflectXRLogo()
                        .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Reflect XR")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Enhancing Life for Wellness")
                            .font(.system(size: 10, weight: .regular))
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
                        HomeCardView(card: card)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Card Model

struct HomeCard: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let fallbackGradient: LinearGradient
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

        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Reflect XR Logo

struct ReflectXRLogo: View {
    private let petals: [(angle: Double, colors: [Color])] = [
        (0,   [Color(red: 0.95, green: 0.35, blue: 0.35), Color(red: 0.95, green: 0.60, blue: 0.20)]),
        (60,  [Color(red: 0.95, green: 0.70, blue: 0.10), Color(red: 0.50, green: 0.85, blue: 0.20)]),
        (120, [Color(red: 0.20, green: 0.80, blue: 0.50), Color(red: 0.10, green: 0.70, blue: 0.90)]),
        (180, [Color(red: 0.25, green: 0.55, blue: 0.95), Color(red: 0.60, green: 0.30, blue: 0.90)]),
        (240, [Color(red: 0.75, green: 0.25, blue: 0.85), Color(red: 0.95, green: 0.30, blue: 0.60)]),
        (300, [Color(red: 0.95, green: 0.40, blue: 0.20), Color(red: 0.95, green: 0.65, blue: 0.10)])
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let petalW = size * 0.38
            let petalH = size * 0.52
            let offset = size * 0.18

            ZStack {
                ForEach(Array(petals.enumerated()), id: \.offset) { index, petal in
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: petal.colors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: petalW, height: petalH)
                        .offset(y: -offset)
                        .rotationEffect(.degrees(petal.angle))
                        .opacity(0.88)
                }
            }
            .frame(width: size, height: size)
        }
    }
}

#Preview {
    HomeView()
}
