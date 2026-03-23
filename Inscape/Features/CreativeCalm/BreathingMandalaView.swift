// BreathingMandalaView.swift

import SwiftUI

// MARK: - Main View

struct BreathingMandalaView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var phase: BreathPhase = .idle
    @State private var outerScale: CGFloat = 1.0
    @State private var middleScale: CGFloat = 1.0
    @State private var innerScale: CGFloat = 1.0
    @State private var outerRotation: Double = 0
    @State private var middleRotation: Double = 0
    @State private var idlePulse: CGFloat = 1.0

    // Petal colors — nil means uncolored
    @State private var outerColors: [Color?] = Array(repeating: nil, count: 12)
    @State private var middleColors: [Color?] = Array(repeating: nil, count: 8)
    @State private var innerColors: [Color?] = Array(repeating: nil, count: 6)

    @State private var selectedColorIndex: Int = 0

    let palette: [Color] = [
        Color(red: 0.62, green: 0.42, blue: 0.92), // violet
        Color(red: 0.48, green: 0.72, blue: 0.98), // sky
        Color(red: 0.92, green: 0.55, blue: 0.78), // rose
        Color(red: 0.48, green: 0.88, blue: 0.78), // mint
        Color(red: 0.98, green: 0.80, blue: 0.45), // gold
        Color(red: 0.78, green: 0.92, blue: 0.58), // sage
    ]

    var selectedColor: Color { palette[selectedColorIndex] }

    enum BreathPhase: Equatable {
        case idle, inhale, hold, exhale

        var label: String {
            switch self {
            case .idle:   return "Tap a petal to begin"
            case .inhale: return "Breathe in…"
            case .hold:   return "Hold…"
            case .exhale: return "Breathe out…"
            }
        }

        var labelOpacity: Double { self == .idle ? 0.55 : 0.90 }
    }

    var body: some View {
        ZStack {
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
                        colorablePetal(
                            width: 36, height: 110, offsetY: -90,
                            angle: Double(i) * 30,
                            baseGradient: LinearGradient(
                                colors: [
                                    Color(red: 0.62, green: 0.42, blue: 0.92).opacity(0.28),
                                    Color(red: 0.48, green: 0.68, blue: 0.95).opacity(0.10)
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            fillColor: outerColors[i]
                        )
                        .onTapGesture { tapPetal(ring: .outer, index: i) }
                    }
                    .scaleEffect(outerScale)
                    .rotationEffect(.degrees(outerRotation))

                    // Middle ring — 8 petals
                    ForEach(0..<8, id: \.self) { i in
                        colorablePetal(
                            width: 26, height: 72, offsetY: -55,
                            angle: Double(i) * 45,
                            baseGradient: LinearGradient(
                                colors: [
                                    Color(red: 0.76, green: 0.55, blue: 0.96).opacity(0.40),
                                    Color(red: 0.76, green: 0.55, blue: 0.96).opacity(0.15)
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            fillColor: middleColors[i]
                        )
                        .onTapGesture { tapPetal(ring: .middle, index: i) }
                    }
                    .scaleEffect(middleScale)
                    .rotationEffect(.degrees(-middleRotation * 0.65))

                    // Inner ring — 6 petals
                    ForEach(0..<6, id: \.self) { i in
                        colorablePetal(
                            width: 18, height: 44, offsetY: -32,
                            angle: Double(i) * 60,
                            baseGradient: LinearGradient(
                                colors: [
                                    Color(red: 0.90, green: 0.78, blue: 1.00).opacity(0.60),
                                    Color(red: 0.90, green: 0.78, blue: 1.00).opacity(0.20)
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            fillColor: innerColors[i]
                        )
                        .onTapGesture { tapPetal(ring: .inner, index: i) }
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
                        .onTapGesture {
                            if phase == .idle || phase == .exhale { startCycle() }
                        }
                }
                .frame(width: 260, height: 260)

                Spacer().frame(height: 48)

                // MARK: Phase label
                Text(phase.label)
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(phase.labelOpacity))
                    .animation(.easeInOut(duration: 0.35), value: phase)

                Spacer().frame(height: 36)

                // MARK: Color palette
                HStack(spacing: 18) {
                    ForEach(palette.indices, id: \.self) { i in
                        let isSelected = selectedColorIndex == i
                        Circle()
                            .fill(palette[i])
                            .frame(width: isSelected ? 36 : 26, height: isSelected ? 36 : 26)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(isSelected ? 0.85 : 0.0), lineWidth: 2)
                            )
                            .shadow(color: palette[i].opacity(isSelected ? 0.7 : 0.0), radius: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColorIndex)
                            .onTapGesture { selectedColorIndex = i }
                    }
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            ZStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    Spacer()
                }
                Text("Creative Calm")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                middleRotation = 360
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                idlePulse = 1.10
            }
        }
    }

    // MARK: - Petal Builder

    @ViewBuilder
    private func colorablePetal(
        width: CGFloat,
        height: CGFloat,
        offsetY: CGFloat,
        angle: Double,
        baseGradient: LinearGradient,
        fillColor: Color?
    ) -> some View {
        ZStack {
            // Base shape — always visible
            Ellipse()
                .fill(baseGradient)
                .frame(width: width, height: height)

            // Color fill — fades in when colored
            if let c = fillColor {
                Ellipse()
                    .fill(c.opacity(0.78))
                    .frame(width: width, height: height)
                    .shadow(color: c.opacity(0.55), radius: 6)
                    .transition(.opacity)
            }
        }
        .frame(width: width, height: height)
        .offset(y: offsetY)
        .rotationEffect(.degrees(angle))
        .animation(.easeInOut(duration: 0.35), value: fillColor != nil)
    }

    // MARK: - Interaction

    enum PetalRing { case outer, middle, inner }

    private func tapPetal(ring: PetalRing, index: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            switch ring {
            case .outer:
                outerColors[index] = (outerColors[index] == nil) ? selectedColor : nil
            case .middle:
                middleColors[index] = (middleColors[index] == nil) ? selectedColor : nil
            case .inner:
                innerColors[index] = (innerColors[index] == nil) ? selectedColor : nil
            }
        }
        if phase == .idle || phase == .exhale {
            startCycle()
        }
    }

    // MARK: - Breath Cycle

    private func startCycle() {
        phase = .inhale
        withAnimation(.easeInOut(duration: 4.0)) {
            outerScale = 1.55
            middleScale = 1.45
            innerScale = 1.65
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            phase = .hold
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            phase = .exhale
            withAnimation(.easeInOut(duration: 4.0)) {
                outerScale = 1.0
                middleScale = 1.0
                innerScale = 1.0
            }
        }

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
