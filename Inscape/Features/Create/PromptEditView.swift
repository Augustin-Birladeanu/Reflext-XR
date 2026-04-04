// PromptEditView.swift

import SwiftUI

struct PromptEditView: View {
    let concept: String
    let subtitle: String
    @State private var editedPrompt: String
    @State private var navigateToResponse = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navManager: NavigationManager

    init(concept: String, subtitle: String, prompt: String) {
        self.concept = concept
        self.subtitle = subtitle
        self._editedPrompt = State(initialValue: prompt)
    }

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
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 4) {
                Text("Prompt Edit")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                Text("Adjust prompt as needed.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            // MARK: Editable prompt box
            TextEditor(text: $editedPrompt)
                .font(.system(size: 16))
                .scrollContentBackground(.hidden)
                .padding(16)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 160)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom) {
            Button { navigateToResponse = true } label: {
                Text("Generate Image")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
        .onChange(of: navManager.popToRoot) { _, popping in
            if popping { dismiss() }
        }
        .navigationDestination(isPresented: $navigateToResponse) {
            ResponseView(prompt: editedPrompt, concept: concept, subtitle: subtitle)
        }
    }
}

#Preview {
    NavigationStack {
        PromptEditView(
            concept: "A Safe Space",
            subtitle: "A safe space for emotions",
            prompt: "Design a safe container where sadness can rest without judgment."
        )
    }
}
