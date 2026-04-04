// PourPaintView.swift

import SwiftUI

struct PourPaintView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var drops: [PourDrop] = []
    @State private var selectedColor: Color = Color(red: 0.55, green: 0.75, blue: 0.95)

    private let paletteColors: [Color] = [
        Color(red: 0.55, green: 0.75, blue: 0.95), // sky blue
        Color(red: 0.75, green: 0.55, blue: 0.90), // soft purple
        Color(red: 0.85, green: 0.55, blue: 0.72), // dusty rose
        Color(red: 0.95, green: 0.72, blue: 0.48), // peach
        Color(red: 0.65, green: 0.88, blue: 0.68), // sage
        Color(red: 0.48, green: 0.85, blue: 0.88), // teal
        Color(red: 0.90, green: 0.85, blue: 0.50), // warm gold
        Color(red: 0.70, green: 0.88, blue: 0.60), // mint
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
                    Button { drops.removeAll() } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                }
                Text("Pour Paint")
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.99, green: 0.96, blue: 0.88))

            // MARK: Canvas
            Canvas { context, size in
                // White background
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.white)
                )

                let radius = min(size.width, size.height) * 0.30

                for drop in drops {
                    let gradient = Gradient(stops: [
                        .init(color: drop.color.opacity(0.82), location: 0.0),
                        .init(color: drop.color.opacity(0.50), location: 0.38),
                        .init(color: drop.color.opacity(0.18), location: 0.70),
                        .init(color: drop.color.opacity(0.00), location: 1.0),
                    ])
                    context.blendMode = .multiply
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: drop.origin.x - radius,
                            y: drop.origin.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )),
                        with: .radialGradient(
                            gradient,
                            center: drop.origin,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture { location in
                drops.append(PourDrop(origin: location, color: selectedColor))
            }

            // MARK: Palette
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(paletteColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(
                                width: selectedColor == color ? 36 : 28,
                                height: selectedColor == color ? 36 : 28
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    .shadow(color: color.opacity(0.6), radius: 4)
                            )
                            .shadow(color: color.opacity(0.40), radius: 6, y: 2)
                            .animation(.spring(response: 0.25), value: selectedColor)
                            .onTapGesture { selectedColor = color }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .background(Color(red: 0.99, green: 0.96, blue: 0.88))
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Model

struct PourDrop: Identifiable {
    let id = UUID()
    let origin: CGPoint
    let color: Color
}

#Preview {
    NavigationStack {
        PourPaintView()
    }
}
