// BreathingMandalaView.swift

import SwiftUI

struct BreathingMandalaView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var phase: BreathPhase = .idle
    @State private var outerScale: CGFloat = 1.0   // driven by breath cycle

    // Hold-to-grow state
    @State private var holdScale: CGFloat = 1.0
    @State private var colorProgress: CGFloat = 0.0
    @State private var growTimer: Timer?
    @State private var drainTimer: Timer?

    @State private var selectedColorIndex: Int = 0

    // Cycles through all four mandalas on each visit
    @AppStorage("breathingMandalaIndex") private var nextMandalaIndex: Int = 0
    @State private var mandalaName: String = "Mandala1"
    private let mandalaNames = ["Mandala1", "Mandala2", "Mandala4"]

    private let maxHoldScale: CGFloat  = 1.65
    private let growRate: CGFloat      = 0.003
    private let colorGrowRate: CGFloat = 0.0046
    private let colorDrainRate: CGFloat = 0.011
    private let holdShrinkRate: CGFloat = 0.65 * 0.011

    let palette: [Color] = [
        Color(red: 0.62, green: 0.42, blue: 0.92), // violet
        Color(red: 0.48, green: 0.72, blue: 0.98), // sky
        Color(red: 0.92, green: 0.55, blue: 0.78), // rose
        Color(red: 0.48, green: 0.88, blue: 0.78), // mint
        Color(red: 0.98, green: 0.80, blue: 0.45), // gold
        Color(red: 0.78, green: 0.92, blue: 0.58), // sage
    ]

    var selectedColor: Color { palette[selectedColorIndex] }

    var revealRadius: CGFloat { max(colorProgress * 155, 1) }

    enum BreathPhase: Equatable {
        case idle, inhale, hold, exhale
        var labelOpacity: Double { self == .idle ? 0.55 : 0.90 }
    }

    var displayLabel: String {
        switch phase {
        case .idle:   return "Hold to color"
        case .inhale: return "Breathe in…"
        case .hold:   return "Release when ready"
        case .exhale: return "Breathe out…"
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.05, blue: 0.18),
                    Color(red: 0.12, green: 0.08, blue: 0.28)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                imageMandala
                    .frame(width: 260, height: 260)

                Spacer().frame(height: 48)

                Text(displayLabel)
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(phase.labelOpacity))
                    .animation(.easeInOut(duration: 0.35), value: phase)

                Spacer().frame(height: 36)

                // Color palette
                HStack(spacing: 18) {
                    ForEach(palette.indices, id: \.self) { i in
                        let isSelected = selectedColorIndex == i
                        Circle()
                            .fill(palette[i])
                            .frame(width: isSelected ? 36 : 26, height: isSelected ? 36 : 26)
                            .overlay(
                                Circle().stroke(Color.white.opacity(isSelected ? 0.85 : 0), lineWidth: 2)
                            )
                            .shadow(color: palette[i].opacity(isSelected ? 0.7 : 0), radius: 8)
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
            // Capture this visit's mandala, then advance for next visit
            mandalaName = mandalaNames[nextMandalaIndex % mandalaNames.count]
            nextMandalaIndex = (nextMandalaIndex + 1) % mandalaNames.count
        }
        .onDisappear { stopAll() }
    }

    // MARK: - Mandala

    @ViewBuilder
    private var imageMandala: some View {
        ZStack {
            Image(mandalaName)
                .resizable()
                .scaledToFit()
                .blendMode(.screen)

            RadialGradient(
                stops: [
                    .init(color: selectedColor,              location: 0.00),
                    .init(color: selectedColor,              location: 0.82),
                    .init(color: selectedColor.opacity(0.4), location: 0.92),
                    .init(color: .clear,                     location: 1.00)
                ],
                center: .center,
                startRadius: 0,
                endRadius: revealRadius
            )
            .mask(Image(mandalaName).resizable().scaledToFit())
            .blendMode(.screen)
            .shadow(color: selectedColor.opacity(colorProgress * 0.6), radius: 18)
        }
        .scaleEffect(holdScale)
        .scaleEffect(outerScale)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if growTimer == nil { startGrowing() }
                    if phase == .idle || phase == .exhale { startCycle() }
                }
                .onEnded { _ in
                    stopGrowing()
                    startDraining()
                    if phase == .hold { startExhale() }
                }
        )
    }

    // MARK: - Timers

    private func startGrowing() {
        drainTimer?.invalidate()
        drainTimer = nil
        guard growTimer == nil else { return }
        growTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in
            holdScale     = min(holdScale     + growRate,      maxHoldScale)
            colorProgress = min(colorProgress + colorGrowRate, 1.0)
        }
    }

    private func stopGrowing() {
        growTimer?.invalidate()
        growTimer = nil
    }

    private func startDraining() {
        drainTimer?.invalidate()
        drainTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in
            holdScale     = max(holdScale     - holdShrinkRate, 1.0)
            colorProgress = max(colorProgress - colorDrainRate, 0.0)
            if holdScale <= 1.0 && colorProgress <= 0.0 {
                drainTimer?.invalidate()
                drainTimer = nil
            }
        }
    }

    private func stopAll() {
        stopGrowing()
        drainTimer?.invalidate()
        drainTimer = nil
    }

    // MARK: - Breath Cycle

    private func startCycle() {
        phase = .inhale
        withAnimation(.easeInOut(duration: 4.0)) {
            outerScale = 1.55
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { phase = .hold }
    }

    private func startExhale() {
        guard phase == .hold else { return }
        phase = .exhale
        withAnimation(.easeInOut(duration: 4.0)) {
            outerScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { phase = .idle }
    }
}

#Preview {
    NavigationStack {
        BreathingMandalaView()
    }
}
