// ReflectView.swift

import SwiftUI

struct ReflectView: View {
    let imageURL: String
    let concept: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navManager: NavigationManager
    @State private var questionIndex = 0
    @State private var reflectionText = ""
    @FocusState private var inputFocused: Bool

    private var questions: [String] { Self.reflectionQuestions(for: concept) }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Text("Reflect")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // MARK: Image
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color(.secondarySystemBackground)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                        )
                default:
                    Color(.secondarySystemBackground)
                        .overlay(ProgressView())
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)

            // MARK: Question row
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        questionIndex = max(0, questionIndex - 1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
                .opacity(questionIndex == 0 ? 0.3 : 1)
                .disabled(questionIndex == 0)

                Text(questions[questionIndex])
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        questionIndex = min(questions.count - 1, questionIndex + 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
                .opacity(questionIndex == questions.count - 1 ? 0.3 : 1)
                .disabled(questionIndex == questions.count - 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                TextField("Share your reflection…", text: $reflectionText, axis: .vertical)
                    .font(.system(size: 16))
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .focused($inputFocused)

                Button {
                    saveAndDismiss()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
        .onChange(of: navManager.popToRoot) { _, popping in
            if popping { dismiss() }
        }
        .onAppear { inputFocused = true }
    }

    // MARK: - Save

    private func saveAndDismiss() {
        let entry = JournalEntry(
            imageURL: imageURL,
            question: questions[questionIndex],
            reflectionText: reflectionText.trimmingCharacters(in: .whitespacesAndNewlines),
            concept: concept
        )
        JournalStore.shared.add(entry)
        inputFocused = false
        navManager.popToRoot = true
    }

    // MARK: - Reflection questions

    private static func reflectionQuestions(for concept: String) -> [String] {
        switch concept {
        case "A Safe Space":
            return [
                "What sticks out to you most about your artwork?",
                "What emotions does this space hold for you?",
                "What would it feel like to rest here?",
            ]
        case "Emotional Waves":
            return [
                "What sticks out to you most about your artwork?",
                "How does this wave mirror what you're feeling right now?",
                "What happens when the wave finally passes?",
            ]
        case "Resilience":
            return [
                "What sticks out to you most about your artwork?",
                "What gives your figure strength in the storm?",
                "Where have you shown this resilience in your own life?",
            ]
        case "Journey":
            return [
                "What sticks out to you most about your artwork?",
                "Where does this road feel like it leads?",
                "What are you carrying with you on this journey?",
            ]
        case "Masks we wear":
            return [
                "What sticks out to you most about your artwork?",
                "What is hidden behind the mask in your image?",
                "When do you feel most free to remove a mask?",
            ]
        case "Crossroads":
            return [
                "What sticks out to you most about your artwork?",
                "Which path feels most like where you are right now?",
                "What would it take to choose a direction?",
            ]
        case "Future Self":
            return [
                "What sticks out to you most about your artwork?",
                "What does your future self know that you don't yet?",
                "What small step could bring you closer to this vision?",
            ]
        case "Letting Go":
            return [
                "What sticks out to you most about your artwork?",
                "What does the thing being released represent for you?",
                "How does it feel to imagine truly letting go?",
            ]
        default:
            return [
                "What sticks out to you most about your artwork?",
                "What feelings arise when you look at this image?",
                "What does this image say about where you are right now?",
            ]
        }
    }
}

#Preview {
    NavigationStack {
        ReflectView(
            imageURL: "",
            concept: "A Safe Space"
        )
    }
}
