// PaintShapesView.swift

import SwiftUI

struct PaintShapesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var shapes: [DrawnShape] = []
    @State private var shapeCounter = 0

    private let palette: [Color] = [
        Color(red: 0.12, green: 0.62, blue: 0.74),
        Color(red: 0.24, green: 0.80, blue: 0.58),
        Color(red: 0.96, green: 0.70, blue: 0.28),
        Color(red: 0.88, green: 0.38, blue: 0.55),
        Color(red: 0.58, green: 0.36, blue: 0.90),
        Color(red: 0.28, green: 0.82, blue: 0.82)
    ]

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
                    Button { shapes.removeAll() } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                }
                Text("Paint Shapes")
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // MARK: Canvas
            GeometryReader { geo in
                ZStack {
                    Color(red: 0.96, green: 0.97, blue: 0.99)

                    Canvas { ctx, _ in
                        for shape in shapes {
                            drawShape(ctx: ctx, shape: shape)
                        }
                    }

                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { value in
                                    addShape(at: value.location)
                                }
                        )
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            // MARK: Hint label
            Text("Drag your finger to paint shapes")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
    }

    // MARK: - Helpers

    private func addShape(at point: CGPoint) {
        // Throttle: skip if last shape is very close
        if let last = shapes.last {
            let dx = last.center.x - point.x
            let dy = last.center.y - point.y
            if sqrt(dx * dx + dy * dy) < 12 { return }
        }
        shapeCounter += 1
        let colorIndex = shapeCounter % palette.count
        let size = CGFloat(28 + (shapeCounter * 13) % 36)   // 28…64
        let kind = ShapeKind.allCases[shapeCounter % ShapeKind.allCases.count]
        shapes.append(DrawnShape(center: point, size: size, kind: kind, color: palette[colorIndex], index: shapeCounter))
    }

    private func drawShape(ctx: GraphicsContext, shape: DrawnShape) {
        let rect = CGRect(
            x: shape.center.x - shape.size / 2,
            y: shape.center.y - shape.size / 2,
            width: shape.size,
            height: shape.size
        )

        let path: Path
        switch shape.kind {
        case .circle:
            path = Path(ellipseIn: rect)
        case .roundedSquare:
            path = Path(roundedRect: rect, cornerRadius: shape.size * 0.25)
        case .triangle:
            path = trianglePath(in: rect)
        case .diamond:
            path = diamondPath(in: rect)
        }

        // Filled shape with soft transparency
        ctx.fill(path, with: .color(shape.color.opacity(0.55)))
        // Slightly darker stroke
        ctx.stroke(path, with: .color(shape.color.opacity(0.80)), lineWidth: 1.5)
    }

    private func trianglePath(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }

    private func diamondPath(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Model

enum ShapeKind: CaseIterable {
    case circle, roundedSquare, triangle, diamond
}

struct DrawnShape: Identifiable {
    let id = UUID()
    let center: CGPoint
    let size: CGFloat
    let kind: ShapeKind
    let color: Color
    let index: Int
}

#Preview {
    NavigationStack {
        PaintShapesView()
    }
}
