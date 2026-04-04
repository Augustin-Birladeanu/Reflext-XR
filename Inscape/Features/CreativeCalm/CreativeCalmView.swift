// CreativeCalmView.swift

import SwiftUI

struct CreativeCalmView: View {
    @Environment(\.dismiss) private var dismiss

    private let activities: [CalmActivity] = [
        CalmActivity(
            title: "Breathing Mandala",
            imageName: "calm_mandala",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.38, green: 0.22, blue: 0.72),
                    Color(red: 0.60, green: 0.38, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            destination: .breathingMandala
        ),
        CalmActivity(
            title: "Finger Painting",
            imageName: "calm_trace",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.42, blue: 0.52),
                    Color(red: 0.96, green: 0.68, blue: 0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            destination: .fingerPainting
        ),
        CalmActivity(
            title: "Floating Bubbles",
            imageName: "calm_bubbles",
            fallbackGradient: LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.28, blue: 0.62),
                    Color(red: 0.18, green: 0.54, blue: 0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            destination: .floatingBubbles
        ),
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
                Text("Creative Calm")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // MARK: Activity Cards
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(activities) { activity in
                        NavigationLink(value: activity.destination) {
                            CalmActivityCard(activity: activity)
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
        .navigationDestination(for: CalmDestination.self) { dest in
            switch dest {
            case .breathingMandala:
                BreathingMandalaView()
            case .fingerPainting:
                FingerPaintingView()
            case .floatingBubbles:
                FloatingBubblesView()
            }
        }
    }
}

// MARK: - Destination

enum CalmDestination: Hashable {
    case breathingMandala
    case fingerPainting
    case floatingBubbles
}

// MARK: - Activity Model

struct CalmActivity: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let fallbackGradient: LinearGradient
    let destination: CalmDestination
}

// MARK: - Card View

struct CalmActivityCard: View {
    let activity: CalmActivity

    var body: some View {
        ZStack {
            if UIImage(named: activity.imageName) != nil {
                Image(activity.imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                activity.fallbackGradient
            }

            // Subtle dark scrim so title stays legible over any image
            LinearGradient(
                colors: [Color.black.opacity(0.28), Color.black.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )

            Text(activity.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        CreativeCalmView()
    }
}
