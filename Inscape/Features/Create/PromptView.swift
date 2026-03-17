// PromptView.swift

import SwiftUI

struct PromptView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @FocusState private var isInputFocused: Bool

    @State private var prompt = ""
    @State private var selectedStyle: String = "Style"
    @State private var navigateToResult = false

    private var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let styleOptions = [
        "Realistic", "Anime", "Watercolor", "Oil Painting",
        "Sketch", "Surrealism", "Minimalist", "Cyberpunk"
    ]

    var body: some View {
        VStack(spacing: 0) {
                // MARK: Custom Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Menu {
                        ForEach(styleOptions, id: \.self) { option in
                            Button(option) { selectedStyle = option }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedStyle)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .overlay(
                            Capsule()
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))

                // MARK: Instructional Text
                Spacer()
                Text("Type into the prompt any emotions you're feeling, or any words that represent symbols or images that come to mind.")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .safeAreaInset(edge: .bottom) {
                // MARK: Input Bar
                HStack(spacing: 12) {
                    TextField("", text: $prompt, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .placeholder(when: prompt.isEmpty) {
                            Text("Describe what you feel or imagine…")
                                .foregroundColor(Color(.placeholderText))
                                .font(.system(size: 15))
                        }
                        .focused($isInputFocused)
                        .lineLimit(1...4)

                    Button {
                        isInputFocused = false
                        navigateToResult = true
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(canSubmit ? Color.primary : Color.secondary.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .disabled(!canSubmit)
                    .animation(.easeInOut(duration: 0.2), value: canSubmit)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(Color(.separator), lineWidth: 1)
                        .background(Color(.systemBackground).clipShape(Capsule()))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))
            }
            .navigationBarHidden(true)
            .onTapGesture { isInputFocused = false }
            .navigationDestination(isPresented: $navigateToResult) {
                ImageResultView(prompt: prompt)
            }
    }
}

// MARK: - Placeholder helper

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    NavigationStack {
        PromptView()
            .environmentObject(SessionManager.shared)
    }
}
