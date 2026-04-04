// FreeTextPromptView.swift

import SwiftUI

struct FreeTextPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    @State private var promptText: String = ""
    @State private var navigateToResult = false

    private var canProceed: Bool {
        !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.bottom, 10)

                Text("How are you feeling today?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("Type any emotions you're feeling, or any words that represent symbols or images that come to mind.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .background(Color(.systemBackground))

            // MARK: Content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        if promptText.isEmpty {
                            Text("e.g. a lion defending his land, teeth bared, wind blowing his proud mane")
                                .font(.system(size: 17))
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $promptText)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .frame(minHeight: 200)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
        }
        .safeAreaInset(edge: .bottom) {
            Button { navigateToResult = true } label: {
                Text("Generate Image")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canProceed ? Color.blue : Color.blue.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canProceed)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .animation(.easeInOut(duration: 0.2), value: canProceed)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToResult) {
            ImageResultView(prompt: promptText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

#Preview {
    NavigationStack {
        FreeTextPromptView()
            .environmentObject(SessionManager.shared)
    }
}
