// BreathingMandalaView.swift

import SwiftUI

// MARK: - Petal Shape

private struct PetalShape: Shape {
    let angleDeg: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let halfWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let a  = CGFloat(angleDeg * .pi / 180)
        let h  = outerRadius - innerRadius

        // Points in upright frame (petal pointing in -y), then rotated by a
        func rot(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: cx + x * cos(a) - y * sin(a),
                    y: cy + x * sin(a) + y * cos(a))
        }

        let base = rot(0,             -innerRadius)
        let tip  = rot(0,             -outerRadius)
        let c1L  = rot(-halfWidth,     -(innerRadius + h * 0.40))
        let c2L  = rot(-halfWidth * 0.38, -(outerRadius - h * 0.16))
        let c1R  = rot( halfWidth * 0.38, -(outerRadius - h * 0.16))
        let c2R  = rot( halfWidth,     -(innerRadius + h * 0.40))

        var p = Path()
        p.move(to: base)
        p.addCurve(to: tip,  control1: c1L, control2: c2L)
        p.addCurve(to: base, control1: c1R, control2: c2R)
        p.closeSubpath()
        return p
    }
}

// MARK: - Ring Shape (reusable circle)

private struct RingShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        return Path(ellipseIn: CGRect(x: cx - radius, y: cy - radius,
                                      width: radius * 2, height: radius * 2))
    }
}

// MARK: - Main View

struct BreathingMandalaView: View {
    @Environment(\.dismiss) private var dismiss

    // Per-section state  (0 = center, 1–8 = inner, 9–16 = outer)
    @State private var fillProgress: [Int: CGFloat] = [:]
    @State private var sectionColor:  [Int: Color]  = [:]

    // Breath state
    @State private var holdingIndex: Int?   = nil
    @State private var phase: BreathPhase   = .idle
    @State private var countdown: Int       = 3
    @State private var fillTimer: Timer?    = nil
    @State private var breathTimer: Timer?  = nil

    @State private var selectedColorIndex: Int = 0

    // Timing
    private let fps: Double        = 60.0
    private let breathDuration     = 3.0
    private var fillStep: CGFloat  { CGFloat(1.0 / (breathDuration * fps)) }
    private var drainStep: CGFloat { fillStep * 1.8 }   // drain ~1.7 s

    // Mandala geometry for 300 pt canvas
    private let canvasSize: CGFloat = 300
    private let centerR: CGFloat    = 24
    private let innerIn: CGFloat    = 28,  innerOut: CGFloat  = 84,  innerHW: CGFloat  = 21
    private let outerIn: CGFloat    = 87,  outerOut: CGFloat  = 148, outerHW: CGFloat  = 29

    let palette: [Color] = [
        Color(red: 0.62, green: 0.42, blue: 0.92), // violet
        Color(red: 0.48, green: 0.72, blue: 0.98), // sky
        Color(red: 0.92, green: 0.55, blue: 0.78), // rose
        Color(red: 0.48, green: 0.88, blue: 0.78), // mint
        Color(red: 0.98, green: 0.80, blue: 0.45), // gold
        Color(red: 0.78, green: 0.92, blue: 0.58), // sage
    ]
    var selectedColor: Color { palette[selectedColorIndex] }

    enum BreathPhase: Equatable { case idle, inhale, exhale }

    var displayLabel: String {
        switch phase {
        case .idle:   return "Touch and hold to breathe"
        case .inhale: return "Inhale... \(countdown)"
        case .exhale: return "Exhale... \(countdown)"
        }
    }

    // Index helpers
    private func innerIdx(_ i: Int) -> Int { i + 1 }
    private func outerIdx(_ i: Int) -> Int { i + 9 }
    private func innerAngle(_ i: Int) -> Double { Double(i) * 45.0 }
    private func outerAngle(_ i: Int) -> Double { Double(i) * 45.0 + 22.5 }

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.05, blue: 0.18),
                    Color(red: 0.12, green: 0.08, blue: 0.28),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 72)

                // Breath label — top of screen
                Text(displayLabel)
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(phase == .idle ? 0.48 : 0.93))
                    .monospacedDigit()
                    .animation(.easeInOut(duration: 0.4), value: phase)

                Spacer()

                // Mandala
                mandalaView
                    .frame(width: canvasSize, height: canvasSize)

                Spacer()

                // Color palette
                HStack(spacing: 18) {
                    ForEach(palette.indices, id: \.self) { i in
                        let sel = selectedColorIndex == i
                        Circle()
                            .fill(palette[i])
                            .frame(width: sel ? 36 : 26, height: sel ? 36 : 26)
                            .overlay(Circle().stroke(Color.white.opacity(sel ? 0.85 : 0), lineWidth: 2))
                            .shadow(color: palette[i].opacity(sel ? 0.7 : 0), radius: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColorIndex)
                            .onTapGesture { selectedColorIndex = i }
                    }
                }

                Spacer().frame(height: 48)
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
        .onDisappear { stopAll() }
    }

    // MARK: - Mandala View

    private var mandalaView: some View {
        ZStack {
            // Decorative rings
            RingShape(radius: outerOut + 2)
                .stroke(Color.white.opacity(0.05), lineWidth: 0.75)
            RingShape(radius: outerIn - 2)
                .stroke(Color.white.opacity(0.09), lineWidth: 0.75)
            RingShape(radius: innerIn - 2)
                .stroke(Color.white.opacity(0.09), lineWidth: 0.75)
            RingShape(radius: centerR + 2)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.75)

            // Outer petals (behind inner)
            ForEach(0..<8, id: \.self) { i in
                sectionBody(
                    index: outerIdx(i),
                    shape: PetalShape(angleDeg:    outerAngle(i),
                                      innerRadius: outerIn,
                                      outerRadius: outerOut,
                                      halfWidth:   outerHW)
                )
            }

            // Inner petals (in front of outer)
            ForEach(0..<8, id: \.self) { i in
                sectionBody(
                    index: innerIdx(i),
                    shape: PetalShape(angleDeg:    innerAngle(i),
                                      innerRadius: innerIn,
                                      outerRadius: innerOut,
                                      halfWidth:   innerHW)
                )
            }

            // Center circle
            sectionBody(index: 0, shape: RingShape(radius: centerR))
        }
    }

    // MARK: - Section View Builder

    @ViewBuilder
    private func sectionBody<S: Shape>(index: Int, shape: S) -> some View {
        let progress = fillProgress[index] ?? 0.0
        let color    = sectionColor[index] ?? selectedColor
        let active   = holdingIndex == index && phase == .inhale

        ZStack {
            // Fill layer
            shape.fill(color.opacity(Double(progress) * 0.82))

            // Active shimmer while inhaling
            if active {
                shape
                    .fill(Color.white.opacity(Double(progress) * 0.12))
                    .blendMode(.screen)
            }

            // Outline
            shape.stroke(
                Color.white.opacity(progress > 0.02 ? 0.26 : 0.14),
                lineWidth: 1.0
            )
        }
        .shadow(color: color.opacity(Double(progress) * 0.50), radius: 10)
        .contentShape(shape)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if holdingIndex != index { startInhale(for: index) }
                }
                .onEnded { _ in
                    if holdingIndex == index { endHold(for: index) }
                }
        )
    }

    // MARK: - Breath Logic

    private func startInhale(for index: Int) {
        guard phase != .exhale else { return }
        stopAll()
        holdingIndex = index
        fillProgress[index] = 0.0       // always restart fill from zero
        phase    = .inhale
        countdown = 3

        // 1-second countdown ticks
        var elapsed = 0
        breathTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            elapsed += 1
            countdown = max(3 - elapsed, 1)
        }

        // 60 fps smooth fill
        fillTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { t in
            let current = fillProgress[index] ?? 0.0
            guard current < 1.0 else { t.invalidate(); fillTimer = nil; return }
            fillProgress[index] = min(current + fillStep, 1.0)
        }
    }

    private func endHold(for index: Int) {
        stopFillTimer()
        stopBreathTimer()
        holdingIndex = nil
        let progress = fillProgress[index] ?? 0.0

        if progress >= 1.0 {
            // Petal fully inhaled — lock color and start exhale
            sectionColor[index] = selectedColor
            beginExhale()
        } else {
            // Lifted early — drain back and return to idle
            drainBack(index: index)
        }
    }

    private func beginExhale() {
        phase     = .exhale
        countdown = 3
        var elapsed = 0
        breathTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            elapsed += 1
            if elapsed >= Int(breathDuration) {
                t.invalidate()
                breathTimer = nil
                withAnimation(.easeInOut(duration: 0.5)) { phase = .idle }
                countdown = 3
            } else {
                countdown = max(3 - elapsed, 1)
            }
        }
    }

    private func drainBack(index: Int) {
        phase = .idle
        fillTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { t in
            let current = fillProgress[index] ?? 0.0
            let next    = max(current - drainStep, 0.0)
            fillProgress[index] = next
            if next <= 0 { t.invalidate(); fillTimer = nil }
        }
    }

    // MARK: - Timer Helpers

    private func stopFillTimer()   { fillTimer?.invalidate();   fillTimer   = nil }
    private func stopBreathTimer() { breathTimer?.invalidate(); breathTimer = nil }
    private func stopAll()         { stopFillTimer(); stopBreathTimer() }
}

#Preview {
    NavigationStack { BreathingMandalaView() }
}
