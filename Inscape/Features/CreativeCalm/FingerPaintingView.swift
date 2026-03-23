// FingerPaintingView.swift

import SwiftUI

struct FingerPaintingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var blobs: [PaintBlob] = []
    @State private var selectedColor: Color = Color(red: 0.88, green: 0.42, blue: 0.62)
    @State private var blobCounter = 0

    private let paletteColors: [Color] = [
        Color(red: 0.88, green: 0.42, blue: 0.62),
        Color(red: 0.96, green: 0.68, blue: 0.36),
        Color(red: 0.42, green: 0.72, blue: 0.88),
        Color(red: 0.55, green: 0.85, blue: 0.62),
        Color(red: 0.72, green: 0.48, blue: 0.90),
        Color(red: 0.95, green: 0.90, blue: 0.42),
        Color(red: 0.40, green: 0.78, blue: 0.78),
        Color(red: 0.92, green: 0.55, blue: 0.40)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header bar
            ZStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Button {
                        blobs.removeAll()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                }
                Text("Creative Calm")
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.99, green: 0.96, blue: 0.88))

            // MARK: Canvas
            GeometryReader { geo in
                ZStack {
                    Color(red: 0.99, green: 0.96, blue: 0.88)

                    Canvas { ctx, _ in
                        for blob in blobs {
                            drawBlob(ctx: ctx, blob: blob)
                        }
                    }

                    // Touch capture layer
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { value in
                                    addBlob(at: value.location)
                                }
                        )
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            // MARK: Colour picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(paletteColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: selectedColor == color ? 36 : 28,
                                   height: selectedColor == color ? 36 : 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    .shadow(color: color.opacity(0.6), radius: 4)
                            )
                            .shadow(color: color.opacity(0.40), radius: 6, y: 2)
                            .animation(.spring(response: 0.25), value: selectedColor)
                            .onTapGesture { selectedColor = color }
                    }

                    // Custom colour wheel
                    ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 28, height: 28)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .background(Color(red: 0.99, green: 0.96, blue: 0.88))
        }
        .navigationBarHidden(true)
    }

    // MARK: - Helpers

    private func addBlob(at point: CGPoint) {
        blobCounter += 1
        blobs.append(PaintBlob(point: point, color: selectedColor, seed: blobCounter))
    }

    private func drawBlob(ctx: GraphicsContext, blob: PaintBlob) {
        // Watercolour layers: large→small, transparent→opaque
        let layers: [(CGFloat, Double)] = [
            (82, 0.04),
            (62, 0.07),
            (44, 0.11),
            (28, 0.17),
            (14, 0.24)
        ]
        let jitter = CGFloat((blob.seed * 7) % 14) - 7  // -7…+7

        for (size, opacity) in layers {
            let s = size + jitter * 0.3
            let rect = CGRect(
                x: blob.point.x - s / 2 + jitter * 0.15,
                y: blob.point.y - s / 2 + jitter * 0.10,
                width: s,
                height: s * (1 + CGFloat((blob.seed * 3) % 10) * 0.01)
            )
            ctx.fill(Path(ellipseIn: rect), with: .color(blob.color.opacity(opacity)))
        }
    }
}

// MARK: - Model

struct PaintBlob: Identifiable {
    let id = UUID()
    let point: CGPoint
    let color: Color
    let seed: Int
}

#Preview {
    NavigationStack {
        FingerPaintingView()
    }
}
