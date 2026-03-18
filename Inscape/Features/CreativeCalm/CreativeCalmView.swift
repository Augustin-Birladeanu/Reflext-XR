// CreativeCalmView.swift

import SwiftUI

struct CreativeCalmView: View {
    @Environment(\.dismiss) private var dismiss

    private let activities: [CalmActivity] = [
        CalmActivity(
            title: "Breathing Mandala",
            subtitle: "Inhale & exhale with gentle animation",
            gradient: LinearGradient(
                colors: [
                    Color(red: 0.38, green: 0.22, blue: 0.72),
                    Color(red: 0.60, green: 0.38, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            icon: "circle.hexagongrid.fill",
            destination: .breathingMandala
        ),
        CalmActivity(
            title: "Finger Painting",
            subtitle: "Soft watercolor blobs with colour picker",
            gradient: LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.42, blue: 0.52),
                    Color(red: 0.96, green: 0.68, blue: 0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            icon: "paintbrush.fill",
            destination: .fingerPainting
        ),
        CalmActivity(
            title: "Paint Shapes",
            subtitle: "Drag to bloom circles and shapes",
            gradient: LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.60, blue: 0.72),
                    Color(red: 0.24, green: 0.78, blue: 0.56)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            icon: "square.on.circle",
            destination: .paintShapes
        ),
        CalmActivity(
            title: "Free Draw",
            subtitle: "Trace glowing lines on a dark canvas",
            gradient: LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.18),
                    Color(red: 0.20, green: 0.12, blue: 0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            icon: "scribble",
            destination: .freeDraw
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
                Text("Creative Calm")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                // Balance the header
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.clear)
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
            case .paintShapes:
                PaintShapesView()
            case .freeDraw:
                FreeDrawView()
            }
        }
    }
}

// MARK: - Destination

enum CalmDestination: Hashable {
    case breathingMandala
    case fingerPainting
    case paintShapes
    case freeDraw
}

// MARK: - Activity Model

struct CalmActivity: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let icon: String
    let destination: CalmDestination
}

// MARK: - Card View

struct CalmActivityCard: View {
    let activity: CalmActivity

    var body: some View {
        ZStack {
            activity.gradient

            HStack(spacing: 16) {
                Image(systemName: activity.icon)
                    .font(.system(size: 34, weight: .light))
                    .foregroundColor(.white.opacity(0.90))
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                    Text(activity.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        CreativeCalmView()
    }
}
