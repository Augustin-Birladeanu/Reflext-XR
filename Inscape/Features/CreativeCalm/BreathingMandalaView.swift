// BreathingMandalaView.swift

import SwiftUI
import AVFoundation

// MARK: - Lotus Petal Shape

private struct LotusPetalShape: Shape {
    let angleDeg: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let halfWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let a  = CGFloat(angleDeg * .pi / 180)
        let h  = outerRadius - innerRadius

        func rot(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: cx + x * cos(a) - y * sin(a),
                    y: cy + x * sin(a) + y * cos(a))
        }

        let base = rot(0,             -innerRadius)
        let tip  = rot(0,             -outerRadius)
        let c1L  = rot(-halfWidth,        -(innerRadius + h * 0.38))
        let c2L  = rot(-halfWidth * 0.40, -(outerRadius - h * 0.13))
        let c1R  = rot( halfWidth * 0.40, -(outerRadius - h * 0.13))
        let c2R  = rot( halfWidth,         -(innerRadius + h * 0.38))

        var p = Path()
        p.move(to: base)
        p.addCurve(to: tip,  control1: c1L, control2: c2L)
        p.addCurve(to: base, control1: c1R, control2: c2R)
        p.closeSubpath()
        return p
    }
}

// Decorative inner teardrop stroke drawn inside each petal
private struct InnerPetalDetail: Shape {
    let angleDeg: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let halfWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let inR  = innerRadius  + (outerRadius - innerRadius) * 0.18
        let outR = outerRadius  - (outerRadius - innerRadius) * 0.18
        let hw   = halfWidth * 0.42
        let h    = outR - inR
        let cx   = rect.midX, cy = rect.midY
        let a    = CGFloat(angleDeg * .pi / 180)

        func rot(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: cx + x * cos(a) - y * sin(a),
                    y: cy + x * sin(a) + y * cos(a))
        }

        let base = rot(0,        -inR)
        let tip  = rot(0,        -outR)
        let c1L  = rot(-hw,       -(inR + h * 0.38))
        let c2L  = rot(-hw * 0.4, -(outR - h * 0.13))
        let c1R  = rot( hw * 0.4, -(outR - h * 0.13))
        let c2R  = rot( hw,        -(inR + h * 0.38))

        var p = Path()
        p.move(to: base)
        p.addCurve(to: tip,  control1: c1L, control2: c2L)
        p.addCurve(to: base, control1: c1R, control2: c2R)
        p.closeSubpath()
        return p
    }
}

// MARK: - Ring Shape

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

    // Section state — 0=center, 1–8=inner, 9–16=middle, 17–24=outer
    @State private var fillProgress: [Int: CGFloat] = [:]
    @State private var sectionColor:  [Int: Color]  = [:]
    @State private var holdingIndex:  Int?  = nil
    @State private var phase: BreathPhase   = .idle
    @State private var countdown: Int       = 1
    @State private var fillTimer: Timer?    = nil
    @State private var breathTimer: Timer?  = nil
    @State private var countdownTasks: [DispatchWorkItem] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isMuted: Bool = false
    @State private var selectedColorIndex: Int = 0

    private let fps: Double        = 60.0
    private let inhaleDuration     = 3.0   // seconds to fill a petal
    private let exhaleDuration     = 5.5   // seconds for exhale phase (matches audio)
    private var drainStep: CGFloat { CGFloat(1.0 / (inhaleDuration * fps)) * 2.0 }

    let palette: [Color] = [
        Color(red: 0.62, green: 0.42, blue: 0.92), // violet
        Color(red: 0.48, green: 0.72, blue: 0.98), // sky
        Color(red: 0.92, green: 0.55, blue: 0.78), // rose
        Color(red: 0.48, green: 0.88, blue: 0.78), // mint
        Color(red: 0.98, green: 0.80, blue: 0.45), // gold
        Color(red: 0.78, green: 0.92, blue: 0.58), // sage
        Color(red: 1.00, green: 0.60, blue: 0.40), // coral
        Color(red: 0.55, green: 0.85, blue: 1.00), // aqua
    ]
    var selectedColor: Color { palette[selectedColorIndex] }

    enum BreathPhase: Equatable { case idle, inhale, exhale }

    var displayLabel: String {
        switch phase {
        case .idle:   return "Touch and hold a petal to breathe"
        case .inhale: return "Inhale... \(countdown)"
        case .exhale: return "Exhale and release... \(countdown)"
        }
    }

    // Index helpers
    private func innerIdx(_ i: Int)  -> Int { i + 1  }
    private func middleIdx(_ i: Int) -> Int { i + 9  }
    private func outerIdx(_ i: Int)  -> Int { i + 17 }
    private func innerAngle(_ i: Int)  -> Double { Double(i) * 45.0 }
    private func middleAngle(_ i: Int) -> Double { Double(i) * 45.0 + 22.5 }
    private func outerAngle(_ i: Int)  -> Double { Double(i) * 45.0 }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let canvasSize = min(geo.size.width, geo.size.height) * 0.90

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.04, blue: 0.16),
                        Color(red: 0.11, green: 0.07, blue: 0.26),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 68)

                    Text(displayLabel)
                        .font(.system(size: 19, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(phase == .idle ? 0.50 : 0.95))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.4), value: phase)

                    Spacer()

                    mandalaView(size: canvasSize)
                        .frame(width: canvasSize, height: canvasSize)

                    Spacer()

                    // Color palette
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(palette.indices, id: \.self) { i in
                                let sel = selectedColorIndex == i
                                Circle()
                                    .fill(palette[i])
                                    .frame(width: sel ? 40 : 28, height: sel ? 40 : 28)
                                    .overlay(Circle().stroke(Color.white.opacity(sel ? 0.90 : 0), lineWidth: 2.5))
                                    .shadow(color: palette[i].opacity(sel ? 0.75 : 0), radius: 10)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColorIndex)
                                    .onTapGesture { selectedColorIndex = i }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 50)
                }
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
                    Button {
                        isMuted.toggle()
                        audioPlayer?.volume = isMuted ? 0 : 1
                    } label: {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                Text("Creative Calm")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .onAppear { setupAudio() }
        .onDisappear { stopAll(); audioPlayer?.stop() }
    }

    // MARK: - Mandala (3 rings + center = 25 sections)

    private func mandalaView(size: CGFloat) -> some View {
        let s        = size / 2
        let centerR  = s * 0.10
        let innerIn  = s * 0.12,  innerOut = s * 0.34,  innerHW  = s * 0.090
        let midIn    = s * 0.36,  midOut   = s * 0.57,  midHW    = s * 0.110
        let outerIn  = s * 0.59,  outerOut = s * 0.80,  outerHW  = s * 0.130

        return ZStack {
            // Guide rings
            RingShape(radius: outerOut  + s * 0.025).stroke(Color.white.opacity(0.08), lineWidth: 1.0)
            RingShape(radius: outerIn   - s * 0.012).stroke(Color.white.opacity(0.13), lineWidth: 0.8)
            RingShape(radius: midIn     - s * 0.012).stroke(Color.white.opacity(0.13), lineWidth: 0.8)
            RingShape(radius: innerIn   - s * 0.010).stroke(Color.white.opacity(0.13), lineWidth: 0.8)
            RingShape(radius: centerR   + s * 0.020).stroke(Color.white.opacity(0.10), lineWidth: 0.75)

            // Outer ring — 8 petals aligned with inner
            ForEach(0..<8, id: \.self) { i in
                sectionBody(
                    index: outerIdx(i),
                    shape: LotusPetalShape(angleDeg: outerAngle(i),
                                           innerRadius: outerIn, outerRadius: outerOut, halfWidth: outerHW),
                    detailAngle: outerAngle(i), detailInR: outerIn, detailOutR: outerOut, detailHW: outerHW
                )
            }

            // Middle ring — 8 petals offset by 22.5°
            ForEach(0..<8, id: \.self) { i in
                sectionBody(
                    index: middleIdx(i),
                    shape: LotusPetalShape(angleDeg: middleAngle(i),
                                           innerRadius: midIn, outerRadius: midOut, halfWidth: midHW),
                    detailAngle: middleAngle(i), detailInR: midIn, detailOutR: midOut, detailHW: midHW
                )
            }

            // Inner ring — 8 petals
            ForEach(0..<8, id: \.self) { i in
                sectionBody(
                    index: innerIdx(i),
                    shape: LotusPetalShape(angleDeg: innerAngle(i),
                                           innerRadius: innerIn, outerRadius: innerOut, halfWidth: innerHW),
                    detailAngle: innerAngle(i), detailInR: innerIn, detailOutR: innerOut, detailHW: innerHW
                )
            }

            // Center circle
            sectionBody(index: 0, shape: RingShape(radius: centerR),
                        detailAngle: 0, detailInR: 0, detailOutR: 0, detailHW: 0)
        }
    }

    // MARK: - Section View Builder

    @ViewBuilder
    private func sectionBody<S: Shape>(
        index: Int,
        shape: S,
        detailAngle: Double,
        detailInR: CGFloat,
        detailOutR: CGFloat,
        detailHW: CGFloat
    ) -> some View {
        let progress = fillProgress[index] ?? 0.0
        let color    = sectionColor[index] ?? selectedColor
        let active   = holdingIndex == index && phase == .inhale
        let isFilled = progress > 0.02
        let isCenter = index == 0

        ZStack {
            shape.fill(color.opacity(Double(progress) * 0.88))

            if active {
                shape
                    .fill(Color.white.opacity(Double(progress) * 0.18))
                    .blendMode(.screen)
            }

            shape.stroke(
                Color.white.opacity(isFilled ? 0.55 : 0.28),
                lineWidth: isFilled ? 2.0 : 1.5
            )

            if !isCenter && detailOutR > 0 {
                InnerPetalDetail(angleDeg: detailAngle,
                                 innerRadius: detailInR,
                                 outerRadius: detailOutR,
                                 halfWidth: detailHW)
                    .stroke(Color.white.opacity(isFilled ? 0.35 : 0.14), lineWidth: 0.75)
            }

            if isCenter {
                RingShape(radius: 5)
                    .fill(Color.white.opacity(isFilled ? 0.60 : 0.22))
            }
        }
        .shadow(color: color.opacity(Double(progress) * 0.60), radius: 14)
        .contentShape(shape)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if holdingIndex != index { startInhale(for: index) }
                }
                .onEnded { _ in
                    // Only drain if we haven't yet auto-completed the inhale
                    if holdingIndex == index && phase == .inhale {
                        endHoldEarly(for: index)
                    }
                }
        )
    }

    // MARK: - Breath Logic

    private func startInhale(for index: Int) {
        guard phase == .idle else { return }
        stopAll()
        holdingIndex = index
        fillProgress[index] = 0.0
        phase     = .inhale
        countdown = 1

        // Audio plays immediately when the user holds the petal
        if !isMuted, let player = audioPlayer {
            player.currentTime = 0
            player.volume = 1
            player.play()
        }

        // Delay the display and fill so the on-screen countdown matches the voice
        let visualDelay: Double = 2.0
        scheduleCountdown([
            (display: 1, at: visualDelay),
            (display: 2, at: visualDelay + 1.2),
            (display: 3, at: visualDelay + 2.2),
        ])

        // Fill timer starts after the same delay so animation matches the voice
        let startDate = Date().addingTimeInterval(visualDelay)
        fillTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { t in
            let elapsed  = max(Date().timeIntervalSince(startDate), 0)
            let progress = CGFloat(min(elapsed / inhaleDuration, 1.0))
            fillProgress[index] = progress
            if progress >= 1.0 {
                t.invalidate()
                fillTimer = nil
                autoCompleteInhale(for: index)
            }
        }
    }

    private func autoCompleteInhale(for index: Int) {
        stopFillTimer()
        holdingIndex = nil
        sectionColor[index] = selectedColor
        beginExhale()
    }

    private func endHoldEarly(for index: Int) {
        stopAll()
        holdingIndex = nil
        drainBack(index: index)
    }

    private func beginExhale() {
        // Fill completes at audio t≈5.0s. Audio cues (absolute):
        //   "Exhale and release" → t=5.6s  (+0.6s from here)
        //   "3"                  → t=7.5s  (+2.5s from here)
        //   "2"                  → t=8.4s  (+3.4s from here)
        //   "1"                  → t=9.6s  (+4.6s from here)

        // Show the exhale label when the voice actually says it
        let showExhale = DispatchWorkItem {
            phase     = .exhale
            countdown = 3
        }
        countdownTasks.append(showExhale)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: showExhale)

        // Countdown numbers timed to match voice
        scheduleCountdown([
            (display: 3, at: 2.5),
            (display: 2, at: 3.4),
            (display: 1, at: 4.6),
        ])

        // Return to idle after audio ends
        breathTimer = Timer.scheduledTimer(withTimeInterval: 5.5, repeats: false) { _ in
            breathTimer = nil
            withAnimation(.easeInOut(duration: 0.5)) { phase = .idle }
            countdown = 1
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

    // MARK: - Countdown Display Scheduling

    private func scheduleCountdown(_ events: [(display: Int, at: Double)]) {
        cancelCountdownTasks()
        for event in events {
            let val  = event.display
            let item = DispatchWorkItem { countdown = val }
            countdownTasks.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + event.at, execute: item)
        }
    }

    private func cancelCountdownTasks() {
        countdownTasks.forEach { $0.cancel() }
        countdownTasks.removeAll()
    }

    // MARK: - Audio

    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: "breathing-guide", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = 0   // play once per breath cycle
            audioPlayer?.prepareToPlay()
        } catch { }
    }

    // Playback is handled directly in startInhale using play(atTime:) for precise sync.

    private func stopFillTimer()   { fillTimer?.invalidate();   fillTimer   = nil }
    private func stopBreathTimer() { breathTimer?.invalidate(); breathTimer = nil }
    private func stopAll()         { stopFillTimer(); stopBreathTimer(); cancelCountdownTasks(); audioPlayer?.stop() }
}

#Preview {
    NavigationStack { BreathingMandalaView() }
}
