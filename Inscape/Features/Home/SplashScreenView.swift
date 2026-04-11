// SplashScreenView.swift

import SwiftUI

struct SplashScreenView: View {

    var onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var textOffset: CGFloat = 16
    @State private var textOpacity: Double = 0
    @State private var screenOpacity: Double = 1

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: -18) {
                Image("home_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: 5) {
                    Text("Reflect Mobile")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Arts for Wellness")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .offset(y: textOffset)
                .opacity(textOpacity)
            }

            VStack {
                Spacer()
                Text("Reflect Mobile is intended to be used for your personal well-being only and should not replace a relationship with a licensed healthcare provider.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .opacity(textOpacity)
            }
        }
        .opacity(screenOpacity)
        .onAppear(perform: runAnimation)
    }

    private func runAnimation() {
        // Phase 1: logo springs in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) {
            logoScale   = 1
            logoOpacity = 1
        }

        // Phase 2: text slides up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                textOffset  = 0
                textOpacity = 1
            }
        }

        // Phase 3: fade out and hand off
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                screenOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            onFinished()
        }
    }
}
