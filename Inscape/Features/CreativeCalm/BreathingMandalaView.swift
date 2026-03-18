// BreathingMandalaView.swift

import SwiftUI

struct BreathingMandalaView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var phase: BreathPhase = .idle
    @State private var outerScale: CGFloat = 1.0
    @State private var middleScale: CGFloat = 1.0
    @State private var innerScale: CGFloat = 1.0
    @State private var outerRotation: Double = 0
    @State private var middleRotation: Double = 0
    @State private var idlePulse: CGFloat = 1.0

    enum BreathPhase: Equatable {
        case idle, inhale, hold, exhale

        var label: String {
            switch self {
            case .idle:    return "Tap to begin"
            case .inhale:  return "Breathe in…"
            case .hold:    return "Hold…"
            case .exhale:  return "Breathe out…"
            }
        }

        var labelOpacity: Double {
            self == .idle ? 0.65 : 0.90
        }
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.05, blue: 0.18),
                    Color(red: 0.12, green: 0.08, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Mandala
                ZStack {
                    // Outer ring — 12 petals
                    ForEach(0..<12, id: \.self) { i in
                        Ellipse()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.62, green: 0.42, blue: 0.92).opacity(0.28),
                                        Color(red: 0.48, green: 0.68, blue: 0.95).opacity(0.10)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 36, height: 110)
                            .offset(y: -90)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                    .scaleEffect(outerScale)
                    .rotationEffect(.degrees(outerRotation))

                    // Middle ring — 8 petals
                    ForEach(0..<8, id: \.self) { i in
                        Ellipse()
                            .fill(
                                Color(red: 0.76, green: 0.55, blue: 0.96).opacity(0.40)
                            )
                            .frame(width: 26, height: 72)
                            .offset(y: -55)
                            .rotationEffect(.degrees(Double(i) * 45))
                    }
                    .scaleEffect(middleScale)
                    .rotationEffect(.degrees(-middleRotation * 0.65))

                    // Inner ring — 6 petals
                    ForEach(0..<6, id: \.self) { i in
                        Ellipse()
                            .fill(
                                Color(red: 0.90, green: 0.78, blue: 1.00).opacity(0.60)
                            )
                            .frame(width: 18, height: 44)
                            .offset(y: -32)
                            .rotationEffect(.degrees(Double(i) * 60))
                    }
                    .scaleEffect(innerScale)
                    .rotationEffect(.degrees(outerRotation * 0.45))

                    // Centre glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color(red: 0.72, green: 0.50, blue: 0.98).opacity(0.60),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color(red: 0.65, green: 0.45, blue: 0.98).opacity(0.9), radius: 16)
                        .scaleEffect(phase == .idle ? idlePulse : 1.0)
                }
                .frame(width: 260, height: 260)
                .onTapGesture {
                    if phase == .idle || phase == .exhale {
                        startCycle()
                    }
                }

                Spacer().frame(height: 52)

                // MARK: Phase label
                Text(phase.label)
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(phase.labelOpacity))
                    .animation(.easeInOut(duration: 0.35), value: phase)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
        .onAppear {
            // Continuous gentle rotation
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                middleRotation = 360
            }
            // Idle pulse
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                idlePulse = 1.10
            }
        }
    }

    // MARK: - Breath Cycle

    private func startCycle() {
        // Inhale: 4 s — expand all layers
        phase = .inhale
        withAnimation(.easeInOut(duration: 4.0)) {
            outerScale = 1.55
            middleScale = 1.45
            innerScale = 1.65
        }

        // Hold: 2 s
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            phase = .hold
        }

        // Exhale: 4 s — contract
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            phase = .exhale
            withAnimation(.easeInOut(duration: 4.0)) {
                outerScale = 1.0
                middleScale = 1.0
                innerScale = 1.0
            }
        }

        // Return to idle
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) {
            phase = .idle
        }
    }
}

#Preview {
    NavigationStack {
        BreathingMandalaView()
    }
}
