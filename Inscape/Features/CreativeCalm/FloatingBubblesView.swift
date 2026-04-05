// FloatingBubblesView.swift

import SwiftUI

// MARK: - Model

struct BubbleModel: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
}

// MARK: - Main View

struct FloatingBubblesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var bubbles: [BubbleModel] = []
    @State private var bubbleColors: [UUID: Color] = [:]
    @State private var poppingIDs: Set<UUID> = []   // mid-pop animation
    @State private var poppedIDs: Set<UUID> = []    // fully removed
    @State private var selectedColorIndex = 0

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
    private let bubbleSizes: [CGFloat] = [44, 56, 68, 80, 96, 114, 130, 150, 170]

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
                        if !poppedIDs.contains(bubble.id) {
                            BubbleView(
                                bubble: bubble,
                                fillColor: bubbleColors[bubble.id],
                                isPopping: poppingIDs.contains(bubble.id),
                                onTap: { handleTap(bubble) }
                            )
                            .position(bubble.position)
                        }
                    }

                    paletteBar
                }
                .onAppear {
                    guard bubbles.isEmpty else { return }
                    bubbles = placeBubbles(in: geo.size)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Tap handler

    private func handleTap(_ bubble: BubbleModel) {
        if bubbleColors[bubble.id] != nil {
            withAnimation(.easeOut(duration: 0.28)) {
                _ = poppingIDs.insert(bubble.id)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                poppedIDs.insert(bubble.id)
                poppingIDs.remove(bubble.id)
            }
        } else {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.58)) {
                bubbleColors[bubble.id] = selectedColor
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

    // MARK: - Layout

    private func placeBubbles(in size: CGSize) -> [BubbleModel] {
        let paletteHeight: CGFloat = 110
        let canvasHeight = size.height - paletteHeight
        var placed: [CGRect] = []
        var result: [BubbleModel] = []
        let sizePool: [CGFloat] = (0..<3).flatMap { _ in bubbleSizes }.shuffled()

        for bSize in sizePool {
            for _ in 0..<40 {
                let x = CGFloat.random(in: bSize / 2 + 8 ... size.width - bSize / 2 - 8)
                let y = CGFloat.random(in: bSize / 2 + 8 ... canvasHeight - bSize / 2 - 8)
                let rect = CGRect(x: x - bSize / 2 - 6, y: y - bSize / 2 - 6,
                                  width: bSize + 12, height: bSize + 12)
                if !placed.contains(where: { $0.intersects(rect) }) {
                    placed.append(rect)
                    result.append(BubbleModel(position: CGPoint(x: x, y: y), size: bSize))
                    break
                }
            }
        }
        return result
    }
}

// MARK: - Bubble View

struct BubbleView: View {
    let bubble: BubbleModel
    let fillColor: Color?
    let isPopping: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Fill
            Circle()
                .fill(fillColor ?? .clear)
                .scaleEffect(fillColor != nil ? 1.0 : 0.001)

            // Outline
            Circle()
                .stroke(
                    fillColor ?? Color.primary.opacity(0.22),
                    lineWidth: bubble.size > 100 ? 2.0 : 1.5
                )

            // Glint
            if fillColor != nil {
                Circle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: bubble.size * 0.22, height: bubble.size * 0.22)
                    .offset(x: -bubble.size * 0.18, y: -bubble.size * 0.18)
            }
        }
        .frame(width: bubble.size, height: bubble.size)
        .contentShape(Circle())
        .scaleEffect(isPopping ? 1.5 : 1.0)
        .opacity(isPopping ? 0.0 : 1.0)
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    NavigationStack {
        FloatingBubblesView()
    }
}
