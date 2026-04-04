// FreeTextPromptView.swift

import SwiftUI

struct FreeTextPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    @State private var promptText: String = ""
    @State private var editableExpanded: String = ""
    @State private var isExpanding = false
    @State private var hasExpanded = false
    @State private var navigateToResult = false
    @State private var expandError: String?

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

                    // Initial prompt input
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
                            .disabled(hasExpanded)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black, lineWidth: 1.5)
                    )

                    // Expanding indicator
                    if isExpanding {
                        HStack(spacing: 10) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.85)
                            Text("Building your prompt…")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    }

                    // Expanded prompt editor
                    if hasExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your prompt")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Feel free to add or change anything before generating.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            TextEditor(text: $editableExpanded)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Error
                    if let error = expandError {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                if hasExpanded {
                    navigateToResult = true
                } else {
                    Task { await expandPrompt() }
                }
            } label: {
                Text(isExpanding ? "Building…" : hasExpanded ? "Generate Image" : "Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canProceed && !isExpanding ? Color.blue : Color.blue.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canProceed || isExpanding)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .animation(.easeInOut(duration: 0.2), value: canProceed)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToResult) {
            ImageResultView(prompt: editableExpanded.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func expandPrompt() async {
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        expandError = nil
        isExpanding = true

        do {
            let expanded = try await APIClient.shared.expandReflection(prompt: trimmed)
            editableExpanded = expanded
            withAnimation { hasExpanded = true }
        } catch {
            expandError = "Couldn't build your prompt. Please try again."
        }

        isExpanding = false
    }
}

#Preview {
    NavigationStack {
        FreeTextPromptView()
            .environmentObject(SessionManager.shared)
    }
}
