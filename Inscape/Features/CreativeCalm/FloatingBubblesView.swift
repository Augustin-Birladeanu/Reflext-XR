// FloatingBubblesView.swift

import SwiftUI
import Combine

// MARK: - Model

struct BubbleModel: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let driftXAmount: CGFloat
    let startY: CGFloat
    let size: CGFloat
    let duration: Double
    var color: Color? = nil
    var isPopping = false
}

// MARK: - Main View

struct FloatingBubblesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var bubbles: [BubbleModel] = []
    @State private var selectedColorIndex = 0
    @State private var screenSize: CGSize = .zero
    @State private var showHint = true

    private let maxBubbles = 8
    private let beige = Color(red: 0.99, green: 0.96, blue: 0.88)

    let palette: [Color] = [
        Color(red: 0.85, green: 0.55, blue: 0.70), // rose
        Color(red: 0.62, green: 0.42, blue: 0.92), // violet
        Color(red: 0.48, green: 0.72, blue: 0.98), // sky
        Color(red: 0.48, green: 0.82, blue: 0.72), // mint
        Color(red: 0.98, green: 0.75, blue: 0.38), // amber
        Color(red: 0.72, green: 0.85, blue: 0.50), // sage
    ]
    var selectedColor: Color { palette[selectedColorIndex] }

    private let spawnTimer = Timer.publish(every: 5.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            ZStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                Text("Creative Calm")
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(beige)

            // MARK: Bubble canvas
            GeometryReader { geo in
                ZStack {
                    beige.ignoresSafeArea()

                    ForEach(bubbles) { b in
                        BubbleView(model: b, onTap: { tap(b) })
                    }

                    VStack(spacing: 0) {
                        if showHint {
                            Text("Tap to colour · tap again to pop")
                                .font(.system(size: 13, weight: .light, design: .rounded))
                                .foregroundColor(.black.opacity(0.25))
                                .padding(.top, 12)
                                .transition(.opacity)
                        }

                        Spacer()

                        // Color palette
                        HStack(spacing: 18) {
                            ForEach(palette.indices, id: \.self) { i in
                                let isSelected = selectedColorIndex == i
                                Circle()
                                    .fill(palette[i].opacity(0.85))
                                    .frame(width: isSelected ? 36 : 26, height: isSelected ? 36 : 26)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(isSelected ? 0.9 : 0), lineWidth: 2.5)
                                    )
                                    .shadow(color: palette[i].opacity(isSelected ? 0.4 : 0), radius: 6)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColorIndex)
                                    .onTapGesture { selectedColorIndex = i }
                            }
                        }
                        .padding(.bottom, 36)
                    }
                }
                .onAppear {
                    screenSize = geo.size
                    // Seed initial bubbles staggered so they appear at different heights
                    for i in 0..<5 {
                        let delay = Double(i) * 0.5
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            spawnBubble(randomStartHeight: true)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        withAnimation(.easeOut(duration: 1.0)) { showHint = false }
                    }
                }
                .onReceive(spawnTimer) { _ in
                    if bubbles.count < maxBubbles { spawnBubble(randomStartHeight: false) }
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Spawning

    private func spawnBubble(randomStartHeight: Bool) {
        guard screenSize != .zero else { return }
        let size = CGFloat.random(in: 120...190)
        let margin = size * 0.4
        let startX = CGFloat.random(in: margin...(screenSize.width - margin))
        let driftX = CGFloat.random(in: -40...40)
        let duration = Double.random(in: 40...58)

        // On first seed, scatter bubbles vertically so screen isn't empty
        let startY = randomStartHeight
            ? CGFloat.random(in: screenSize.height * 0.3 ... screenSize.height + size)
            : screenSize.height + size

        let bubble = BubbleModel(
            startX: startX,
            driftXAmount: driftX,
            startY: startY,
            size: size,
            duration: duration
        )
        bubbles.append(bubble)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 2) {
            bubbles.removeAll { $0.id == bubble.id }
        }
    }

    // MARK: - Interaction

    private func tap(_ b: BubbleModel) {
        guard let i = bubbles.firstIndex(where: { $0.id == b.id }) else { return }
        if bubbles[i].color != nil {
            bubbles[i].isPopping = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                bubbles.removeAll { $0.id == b.id }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.45)) {
                bubbles[i].color = selectedColor
            }
        }
    }
}

// MARK: - Bubble View

struct BubbleView: View {
    let model: BubbleModel
    let onTap: () -> Void

    @State private var driftY: CGFloat = 0
    @State private var driftX: CGFloat = 0
    @State private var swayX: CGFloat = 0
    @State private var breathScale: CGFloat = 1.0
    @State private var popScale: CGFloat = 1.0
    @State private var opacity: Double = 0.0

    // Uncolored: warm sand so circles are subtly visible; colored: user's choice
    private var displayColor: Color {
        model.color ?? Color(red: 0.88, green: 0.80, blue: 0.70)
    }
    private var isColored: Bool { model.color != nil }

    var body: some View {
        ZStack {
            // Outer bloom — large, heavily blurred for soft watercolor edge
            Circle()
                .fill(displayColor.opacity(isColored ? 0.55 : 0.45))
                .blur(radius: 22)

            // Mid layer
            Circle()
                .fill(displayColor.opacity(isColored ? 0.45 : 0.32))
                .padding(model.size * 0.08)
                .blur(radius: 10)

            // Core — slightly crisper centre
            Circle()
                .fill(displayColor.opacity(isColored ? 0.35 : 0.22))
                .padding(model.size * 0.20)
                .blur(radius: 4)
        }
        .frame(width: model.size, height: model.size)
        .scaleEffect(popScale * breathScale)
        .opacity(opacity)
        .position(
            x: model.startX + driftX + swayX,
            y: model.startY + driftY
        )
        .onTapGesture(perform: onTap)
        .onAppear {
            // Slow fade in
            withAnimation(.easeIn(duration: 1.4)) { opacity = 1.0 }

            // Upward drift
            withAnimation(.linear(duration: model.duration)) {
                driftY = -(model.startY + model.size + 60)
                driftX = model.driftXAmount
            }

            // Gentle lateral sway
            let swayAmt = CGFloat.random(in: 14...30)
            let swayDir: CGFloat = Bool.random() ? 1 : -1
            let swayDur = Double.random(in: 5.0...8.0)
            withAnimation(.easeInOut(duration: swayDur).repeatForever(autoreverses: true)) {
                swayX = swayDir * swayAmt
            }

            // Slow breathing pulse
            let breathDur = Double.random(in: 4.5...7.0)
            withAnimation(.easeInOut(duration: breathDur).repeatForever(autoreverses: true)) {
                breathScale = CGFloat.random(in: 1.04...1.10)
            }
        }
        .onChange(of: model.isPopping) { isPopping in
            if isPopping {
                withAnimation(.easeOut(duration: 0.32)) {
                    popScale = 1.5
                    opacity = 0
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FloatingBubblesView()
    }
}
