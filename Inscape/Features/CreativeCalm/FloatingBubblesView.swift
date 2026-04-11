// FloatingBubblesView.swift

import SwiftUI

// MARK: - Model

struct FloatingBubble: Identifiable {
    let id = UUID()
    let xFraction: CGFloat    // 0.0–1.0 fraction of canvas width
    let size: CGFloat
    let duration: Double      // seconds to travel from bottom to top
    let wobbleAmount: CGFloat
    var fillColor: Color? = nil
    var isPopping: Bool = false
}

// MARK: - Main View

struct FloatingBubblesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var bubbles: [FloatingBubble] = []
    @State private var selectedColorIndex = 0
    @State private var canvasSize: CGSize = .zero
    @State private var spawnTimer: Timer? = nil

    private let palette: [Color] = [
        Color(red: 0.85, green: 0.55, blue: 0.70),
        Color(red: 0.62, green: 0.42, blue: 0.92),
        Color(red: 0.48, green: 0.72, blue: 0.98),
        Color(red: 0.48, green: 0.82, blue: 0.72),
        Color(red: 0.98, green: 0.75, blue: 0.38),
        Color(red: 0.72, green: 0.85, blue: 0.50),
        Color(red: 0.98, green: 0.50, blue: 0.45),
        Color(red: 0.80, green: 0.70, blue: 0.98),
    ]
    private var selectedColor: Color { palette[selectedColorIndex] }
    private let bubbleSizes: [CGFloat] = [38, 50, 62, 76, 90, 106, 124]

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
                Text("Floating Bubbles")
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // MARK: Canvas
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    Color(.systemBackground).ignoresSafeArea()

                    ForEach(bubbles) { bubble in
                        FloatingBubbleView(
                            bubble: bubble,
                            canvasHeight: geo.size.height,
                            canvasWidth: geo.size.width,
                            onTap: { handleTap(bubble) }
                        )
                    }

                    paletteBar
                }
                .onAppear {
                    guard canvasSize == .zero else { return }
                    canvasSize = geo.size
                    startSpawning()
                }
                .onDisappear {
                    spawnTimer?.invalidate()
                    spawnTimer = nil
                    bubbles.removeAll()
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Spawning

    private func startSpawning() {
        // Staggered initial burst so the screen fills naturally
        for i in 0..<7 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.65) {
                spawnBubble()
            }
        }

        // Steady calm rhythm after the burst
        let timer = Timer.scheduledTimer(withTimeInterval: 1.25, repeats: true) { _ in
            spawnBubble()
        }
        RunLoop.main.add(timer, forMode: .common)
        spawnTimer = timer
    }

    private func spawnBubble() {
        guard canvasSize != .zero else { return }
        let size = bubbleSizes.randomElement()!
        let margin = size / 2 + 14
        let xFrac = CGFloat.random(in: (margin / canvasSize.width)...(1 - margin / canvasSize.width))
        let duration = Double.random(in: 7.5...12.0)
        let wobble = CGFloat.random(in: 8...22)

        let bubble = FloatingBubble(
            xFraction: xFrac,
            size: size,
            duration: duration,
            wobbleAmount: wobble
        )
        bubbles.append(bubble)

        // Remove after it exits the top
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1.5) {
            bubbles.removeAll { $0.id == bubble.id }
        }
    }

    // MARK: - Tap

    private func handleTap(_ bubble: FloatingBubble) {
        guard let idx = bubbles.firstIndex(where: { $0.id == bubble.id }) else { return }

        if bubbles[idx].fillColor == nil {
            // Fill with selected color
            withAnimation(.spring(response: 0.45, dampingFraction: 0.58)) {
                bubbles[idx].fillColor = selectedColor
            }
        } else {
            // Pop filled bubble
            withAnimation(.easeOut(duration: 0.25)) {
                bubbles[idx].isPopping = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bubbles.removeAll { $0.id == bubble.id }
            }
        }
    }

    // MARK: - Palette bar

    private var paletteBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(palette.indices, id: \.self) { i in
                    let selected = selectedColorIndex == i
                    Circle()
                        .fill(palette[i])
                        .frame(width: selected ? 38 : 28, height: selected ? 38 : 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: selected ? 3 : 0))
                        .shadow(color: palette[i].opacity(0.4), radius: selected ? 6 : 2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selectedColorIndex)
                        .onTapGesture { selectedColorIndex = i }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Individual Floating Bubble View

/// Each bubble manages its own upward float and wobble animations via @State.
/// When the parent updates `bubble.fillColor` or `bubble.isPopping`, SwiftUI
/// re-renders this view with the new values while preserving the in-flight
/// yPos / xOffset animations (same view identity via bubble.id).
struct FloatingBubbleView: View {
    let bubble: FloatingBubble
    let canvasHeight: CGFloat
    let canvasWidth: CGFloat
    let onTap: () -> Void

    @State private var yPos: CGFloat
    @State private var xOffset: CGFloat = 0

    init(bubble: FloatingBubble, canvasHeight: CGFloat, canvasWidth: CGFloat, onTap: @escaping () -> Void) {
        self.bubble = bubble
        self.canvasHeight = canvasHeight
        self.canvasWidth = canvasWidth
        self.onTap = onTap
        // Start just below the visible canvas
        _yPos = State(initialValue: canvasHeight + bubble.size / 2)
    }

    private var startX: CGFloat { bubble.xFraction * canvasWidth }

    var body: some View {
        ZStack {
            // Glassy inner fill (subtle even when empty, brighter when filled)
            Circle()
                .fill(
                    bubble.fillColor.map { _ in Color.clear } ??
                    Color.white.opacity(0.06)
                )

            // Color fill (animates in on tap)
            if let color = bubble.fillColor {
                Circle()
                    .fill(color)
                    .transition(.scale.combined(with: .opacity))
            }

            // Stroke — iridescent gradient when empty, colored when filled
            Circle()
                .stroke(
                    bubble.fillColor.map { _ in
                        AnyShapeStyle(bubble.fillColor ?? Color.clear)
                    } ?? AnyShapeStyle(
                        AngularGradient(
                            colors: [
                                Color(red: 0.62, green: 0.82, blue: 0.98).opacity(0.75),
                                Color(red: 0.85, green: 0.65, blue: 0.95).opacity(0.75),
                                Color(red: 0.98, green: 0.82, blue: 0.65).opacity(0.55),
                                Color(red: 0.60, green: 0.92, blue: 0.85).opacity(0.70),
                                Color(red: 0.62, green: 0.82, blue: 0.98).opacity(0.75),
                            ],
                            center: .center
                        )
                    ),
                    lineWidth: bubble.size > 100 ? 2.5 : 2.0
                )

            // Glint highlight
            Circle()
                .fill(Color.white.opacity(bubble.fillColor != nil ? 0.30 : 0.18))
                .frame(width: bubble.size * 0.22, height: bubble.size * 0.22)
                .offset(x: -bubble.size * 0.18, y: -bubble.size * 0.18)
        }
        .frame(width: bubble.size, height: bubble.size)
        .contentShape(Circle())
        .scaleEffect(bubble.isPopping ? 1.6 : 1.0)
        .opacity(bubble.isPopping ? 0.0 : 1.0)
        .position(x: startX + xOffset, y: yPos)
        .onTapGesture(perform: onTap)
        .onAppear {
            // Float upward — linear so speed stays constant
            withAnimation(.linear(duration: bubble.duration)) {
                yPos = -bubble.size / 2
            }
            // Gentle horizontal drift
            let wobbleTarget = CGFloat.random(in: -bubble.wobbleAmount...bubble.wobbleAmount)
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.8...2.8))
                .repeatForever(autoreverses: true)
            ) {
                xOffset = wobbleTarget
            }
        }
    }
}

#Preview {
    NavigationStack {
        FloatingBubblesView()
    }
}
