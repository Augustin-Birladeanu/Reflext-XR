// PourPaintView.swift

import SwiftUI

// MARK: - View

struct PourPaintView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blobs: [PourBlob] = []
    @State private var selectedColor: Color = Color(red: 0.80, green: 0.38, blue: 0.22)
    @State private var swirlPhase: CGFloat = 0
    @State private var isSwirling = false

    private static let palette: [Color] = [
        Color(red: 0.80, green: 0.38, blue: 0.22),  // terracotta
        Color(red: 0.08, green: 0.55, blue: 0.70),  // deep teal
        Color(red: 0.95, green: 0.93, blue: 0.88),  // off-white
        Color(red: 0.06, green: 0.20, blue: 0.42),  // navy
        Color(red: 0.88, green: 0.65, blue: 0.15),  // gold
        Color(red: 0.18, green: 0.68, blue: 0.60),  // turquoise
        Color(red: 0.55, green: 0.15, blue: 0.45),  // plum
        Color(red: 0.72, green: 0.22, blue: 0.18),  // deep red
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
                    Button {
                        blobs.removeAll()
                        swirlPhase = 0
                        isSwirling = false
                    } label: {
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
            GeometryReader { geo in
                let minDim = min(geo.size.width, geo.size.height)

                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        context.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .color(.white)
                        )

                        let now = timeline.date
                        let phase = swirlPhase

                        // ── Base: organic expanding blobs ──────────────────
                        for blob in blobs {
                            if let path = blob.path(at: now) {
                                context.fill(path, with: .color(blob.color))
                            }
                        }

                        // ── Marble overlay: fades in then animates ─────────
                        // Only shown when ≥ 2 colours and swirl has started.
                        if phase > 0.01, blobs.count >= 2 {
                            // Reach full opacity quickly so the flow is the main spectacle
                            let overlayOpacity = min(phase / 0.35, 1.0)
                            var mCtx = context
                            mCtx.opacity = overlayOpacity
                            drawMarble(&mCtx, size: size, blobs: blobs, phase: phase)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                blobs.append(PourBlob(
                                    at: value.startLocation,
                                    color: selectedColor,
                                    maxRadius: minDim * 0.36
                                ))
                            }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: Swirl button + Palette
            VStack(spacing: 0) {
                Button {
                    guard !isSwirling, blobs.count >= 2 else { return }
                    isSwirling = true
                    withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 4.5)) {
                        swirlPhase += 1.4
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.6) {
                        isSwirling = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hurricane")
                            .rotationEffect(isSwirling ? .degrees(360) : .degrees(0))
                            .animation(isSwirling ? .linear(duration: 4.5) : .default,
                                       value: isSwirling)
                        Text("Swirl")
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            (isSwirling || blobs.count < 2)
                                ? Color.gray.opacity(0.45)
                                : Color(red: 0.20, green: 0.45, blue: 0.72)
                        )
                    )
                }
                .disabled(isSwirling || blobs.count < 2)
                .padding(.top, 14)
                .padding(.bottom, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Self.palette, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(
                                    width: selectedColor == color ? 36 : 28,
                                    height: selectedColor == color ? 36 : 28
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white,
                                                      lineWidth: selectedColor == color ? 3 : 0)
                                        .shadow(color: color.opacity(0.6), radius: 4)
                                )
                                .shadow(color: color.opacity(0.45), radius: 6, y: 2)
                                .animation(.spring(response: 0.25), value: selectedColor)
                                .onTapGesture { selectedColor = color }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
            }
            .background(Color(red: 0.99, green: 0.96, blue: 0.88))
        }
        .navigationBarHidden(true)
    }

    // MARK: - Spiral swirl renderer

    /// Scans the canvas in thin strips.
    /// For each sample point it applies a spiral rotation around the canvas centre —
    /// outer points rotate more than inner ones, pulling the blob Voronoi regions into
    /// curved spiral bands.  As `phase` grows the spiral tightens, simulating the canvas
    /// being spun from the centre outward.
    private func drawMarble(_ context: inout GraphicsContext,
                            size: CGSize,
                            blobs: [PourBlob],
                            phase: CGFloat) {
        let W = size.width, H = size.height
        let cx = W / 2, cy = H / 2
        let maxR = sqrt(cx * cx + cy * cy)

        let stripH: CGFloat = 1.5
        let stepX:  CGFloat = 1.5
        let numStrips = Int(ceil(H / stripH)) + 1

        for strip in 0..<numStrips {
            let y = CGFloat(strip) * stripH + stripH * 0.5

            var segStart: CGFloat = 0
            var prevIdx:  Int     = -1

            var x: CGFloat = 0
            while x <= W + stepX {
                let px = min(x, W)

                let dx = px - cx
                let dy = y  - cy
                let r  = sqrt(dx * dx + dy * dy)

                // Spiral angle: uniform base rotation + extra twist that grows with radius.
                // This stretches outer blob regions into spiral arms while the centre
                // stays relatively anchored.
                let spiralAngle = phase * (2.4 + (r / maxR) * 3.2)
                let cosA = cos(spiralAngle)
                let sinA = sin(spiralAngle)

                // Distorted lookup point in blob space
                let lx = cx + dx * cosA - dy * sinA
                let ly = cy + dx * sinA + dy * cosA

                // Nearest blob (Voronoi) at the distorted position
                var minDist = CGFloat.infinity
                var nearest = 0
                for (i, blob) in blobs.enumerated() {
                    let bx = lx - blob.origin.x
                    let by = ly - blob.origin.y
                    let d  = bx * bx + by * by
                    if d < minDist { minDist = d; nearest = i }
                }

                // Merge same-colour runs into one rectangle
                if nearest != prevIdx {
                    if prevIdx >= 0, px > segStart {
                        let rect = CGRect(x: segStart,
                                          y: CGFloat(strip) * stripH,
                                          width: px - segStart,
                                          height: stripH)
                        context.fill(Path(rect), with: .color(blobs[prevIdx].color))
                    }
                    prevIdx  = nearest
                    segStart = px
                }

                x += stepX
            }

            // Flush last run
            if prevIdx >= 0, W > segStart {
                let rect = CGRect(x: segStart,
                                  y: CGFloat(strip) * stripH,
                                  width: W - segStart,
                                  height: stripH)
                context.fill(Path(rect), with: .color(blobs[prevIdx].color))
            }
        }
    }
}

// MARK: - Pour Blob

struct PourBlob: Identifiable {
    let id = UUID()
    let origin: CGPoint
    let color: Color
    let maxRadius: CGFloat
    let createdAt: Date

    let jitter: [CGFloat]
    let waveFrequency: CGFloat
    let waveSeed: Double

    private static let pointCount     = 22
    private static let expandDuration = 2.6
    private static let settleDuration = 2.0

    init(at origin: CGPoint, color: Color, maxRadius: CGFloat) {
        self.origin        = origin
        self.color         = color
        self.maxRadius     = maxRadius
        self.createdAt     = Date()
        self.jitter        = (0..<Self.pointCount).map { _ in CGFloat.random(in: 0.82..<1.18) }
        self.waveFrequency = CGFloat.random(in: 2.0..<4.5)
        self.waveSeed      = Double.random(in: 0..<(.pi * 2))
    }

    /// Organic expanding blob — drawn beneath the marble overlay.
    func path(at now: Date) -> Path? {
        let elapsed = now.timeIntervalSince(createdAt)

        let et = CGFloat(min(elapsed / Self.expandDuration, 1.0))
        let r  = maxRadius * et * et * (3 - 2 * et)
        guard r > 2 else { return nil }

        let totalSettle = Self.expandDuration + Self.settleDuration
        let st  = CGFloat(min(elapsed / totalSettle, 1.0))
        let ste = st * st * (3 - 2 * st)
        let waveAmp   = CGFloat(13 * (1 - ste) + 2.5 * ste)
        let wavePhase = CGFloat(min(elapsed, totalSettle) * 1.4)

        let n   = jitter.count
        let pts = (0..<n).map { i -> CGPoint in
            let angle = CGFloat(i) / CGFloat(n) * 2 * .pi
            let baseR = r * jitter[i]
            let wave  = waveAmp * sin(CGFloat(i) * waveFrequency + CGFloat(waveSeed) + wavePhase)
            return CGPoint(
                x: origin.x + cos(angle) * (baseR + wave),
                y: origin.y + sin(angle) * (baseR + wave)
            )
        }
        return catmullRomPath(pts)
    }

    private func catmullRomPath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        let n = pts.count
        guard n >= 3 else { return path }
        let k: CGFloat = 0.4 / 3

        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n]
            let p1 = pts[i]
            let p2 = pts[(i + 1) % n]
            let p3 = pts[(i + 2) % n]
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) * k, y: p1.y + (p2.y - p0.y) * k)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) * k, y: p2.y - (p3.y - p1.y) * k)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    NavigationStack { PourPaintView() }
}
