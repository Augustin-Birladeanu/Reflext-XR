// ReflectFromSelectedImageView.swift

import SwiftUI

struct ReflectFromSelectedImageView: View {
    let imageName: String       // asset name (e.g. "preset-hands") or remote URL
    let category: String

    @Environment(\.dismiss) private var dismiss

    @State private var questionIndex = 0
    @State private var reflectionText = ""
    @State private var navigateToResponse = false
    @FocusState private var isInputFocused: Bool

    private let questions: [String] = [
        "What sticks out to you most about your artwork?",
        "What emotions does this image bring up for you?",
        "What does this image remind you of in your own life?",
    ]

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            ZStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                Text("Reflect")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Subtitle
                    Text("Reflect on your artwork")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                    // MARK: Image + question overlay
                    ZStack(alignment: .bottom) {
                        // Render named asset or fall back to AsyncImage for URLs
                        if UIImage(named: imageName) != nil {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
                            AsyncImage(url: URL(string: imageName)) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                case .failure:
                                    Color(.systemGray5)
                                        .overlay(Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary))
                                default:
                                    Color(.systemGray5).overlay(ProgressView())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        // Question card
                        HStack(spacing: 12) {
                            Button {
                                if questionIndex > 0 {
                                    withAnimation(.easeInOut(duration: 0.2)) { questionIndex -= 1 }
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(questionIndex == 0 ? Color(.tertiaryLabel) : .primary)
                            }
                            .disabled(questionIndex == 0)

                            Text(questions[questionIndex])
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .animation(.easeInOut(duration: 0.2), value: questionIndex)

                            Button {
                                if questionIndex < questions.count - 1 {
                                    withAnimation(.easeInOut(duration: 0.2)) { questionIndex += 1 }
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(questionIndex == questions.count - 1 ? Color(.tertiaryLabel) : .primary)
                            }
                            .disabled(questionIndex == questions.count - 1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                    }
                    .padding(.horizontal, 16)

                    // MARK: Text input + submit
                    HStack(alignment: .center, spacing: 12) {
                        TextField(
                            "Feeling connected, feeling love…",
                            text: $reflectionText,
                            axis: .vertical
                        )
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .focused($isInputFocused)

                        Button {
                            navigateToResponse = true
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(
                                    reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color(.tertiaryLabel) : .blue
                                )
                        }
                        .disabled(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(14)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .onTapGesture { isInputFocused = false }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToResponse) {
            ImageResultView(prompt: reflectionText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

#Preview {
    NavigationStack {
        ReflectFromSelectedImageView(imageName: "preset-hands", category: "Emotions")
    }
}
