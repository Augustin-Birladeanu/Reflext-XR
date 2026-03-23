// FreeDrawView.swift

import SwiftUI

struct FreeDrawView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var completedStrokes: [DrawStroke] = []
    @State private var activePoints: [CGPoint] = []
    @State private var selectedColor: Color = Color(red: 0.55, green: 0.85, blue: 1.00)

    private let glowColors: [Color] = [
        Color(red: 0.55, green: 0.85, blue: 1.00),  // cyan
        Color(red: 0.80, green: 0.50, blue: 1.00),  // purple
        Color(red: 1.00, green: 0.55, blue: 0.75),  // pink
        Color(red: 0.50, green: 1.00, blue: 0.75),  // mint
        Color(red: 1.00, green: 0.85, blue: 0.40),  // gold
        Color(red: 0.40, green: 0.80, blue: 1.00)   // sky
    ]

    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.06, green: 0.05, blue: 0.14)
                .ignoresSafeArea()

            // MARK: Glow layer (blurred, soft)
            Canvas { ctx, _ in
                renderStrokes(ctx: ctx, lineWidth: 14, opacity: 0.22)
                renderActive(ctx: ctx, lineWidth: 14, opacity: 0.22)
            }
            .blur(radius: 10)

            // MARK: Core layer (sharp, bright)
            Canvas { ctx, _ in
                renderStrokes(ctx: ctx, lineWidth: 2.5, opacity: 0.95)
                renderActive(ctx: ctx, lineWidth: 2.5, opacity: 0.95)
            }

            // Touch capture
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            activePoints.append(value.location)
                        }
                        .onEnded { _ in
                            if activePoints.count > 1 {
                                completedStrokes.append(
                                    DrawStroke(points: activePoints, color: selectedColor)
                                )
                            }
                            activePoints = []
                        }
                )
                .ignoresSafeArea()

            // MARK: UI overlay
            VStack {
                // Top bar
                ZStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        Spacer()
                        Button {
                            completedStrokes.removeAll()
                            activePoints = []
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    Text("Creative Calm")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Colour swatches at bottom
                HStack(spacing: 14) {
                    ForEach(glowColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(
                                width: selectedColor == color ? 34 : 26,
                                height: selectedColor == color ? 34 : 26
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.8), lineWidth: selectedColor == color ? 2 : 0)
                            )
                            .shadow(color: color.opacity(0.85), radius: 8)
                            .animation(.spring(response: 0.25), value: selectedColor)
                            .onTapGesture { selectedColor = color }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                )
                .padding(.bottom, 28)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Rendering

    private func renderStrokes(ctx: GraphicsContext, lineWidth: CGFloat, opacity: Double) {
        for stroke in completedStrokes {
            let path = smoothPath(from: stroke.points)
            ctx.stroke(path, with: .color(stroke.color.opacity(opacity)), lineWidth: lineWidth)
        }
    }

    private func renderActive(ctx: GraphicsContext, lineWidth: CGFloat, opacity: Double) {
        guard activePoints.count > 1 else { return }
        let path = smoothPath(from: activePoints)
        ctx.stroke(path, with: .color(selectedColor.opacity(opacity)), lineWidth: lineWidth)
    }

    // Quadratic Bézier through midpoints for smooth curves
    private func smoothPath(from points: [CGPoint]) -> Path {
        guard points.count >= 2 else { return Path() }
        var path = Path()
        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        for i in 1..<points.count - 1 {
            let mid = CGPoint(
                x: (points[i].x + points[i + 1].x) / 2,
                y: (points[i].y + points[i + 1].y) / 2
            )
            path.addQuadCurve(to: mid, control: points[i])
        }
        path.addLine(to: points[points.count - 1])
        return path
    }
}

// MARK: - Model

struct DrawStroke {
    let points: [CGPoint]
    let color: Color
}

#Preview {
    NavigationStack {
        FreeDrawView()
    }
}
