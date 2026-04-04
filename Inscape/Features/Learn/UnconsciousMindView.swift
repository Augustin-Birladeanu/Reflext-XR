// UnconsciousMindView.swift

import SwiftUI

struct UnconsciousMindView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GenerateViewModel()
    @State private var reflectionText: String = ""
    @State private var editableExpanded: String = ""
    @State private var postImageReflection: String = ""
    @State private var savedToLibrary = false
    @FocusState private var isReflectionFocused: Bool
    @FocusState private var isPostImageFocused: Bool

    private let store = JournalStore.shared

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
                Text("The Unconscious Mind")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()

            // MARK: Scrollable Content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Hero image
                    Image("learnUI-self")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()

                    // Body content
                    VStack(alignment: .leading, spacing: 24) {

                        // Insights
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Insights")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Much of what we do is influenced by the unconscious mind — hidden thoughts, memories, and feelings we're not fully aware of. One way to understand these hidden parts of ourselves is through art. Through symbols and images, we can express and better understand what is going on beneath the surface.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Reflection input
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reflection")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Jot down words that relate to how you feel right now.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            ZStack(alignment: .topLeading) {
                                if reflectionText.isEmpty {
                                    Text("I feel...")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(.placeholderText))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 13)
                                }
                                TextEditor(text: $reflectionText)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                    .focused($isReflectionFocused)
                                    .frame(minHeight: 90)
                                    .scrollContentBackground(.hidden)
                                    .scrollDisabled(true)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                            }
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isReflectionFocused ? Color.blue : Color(.systemGray4),
                                        lineWidth: 1
                                    )
                            )
                        }

                        // Error
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

                        // Generate button
                        Button {
                            isReflectionFocused = false
                            if viewModel.generatedImageURL != nil {
                                savedToLibrary = false
                                postImageReflection = ""
                                viewModel.generatedImageURL = nil
                                viewModel.expandedPrompt = nil
                                editableExpanded = ""
                                viewModel.prompt = reflectionText
                                Task { await viewModel.expandReflection() }
                            } else if viewModel.expandedPrompt == nil {
                                viewModel.prompt = reflectionText
                                Task { await viewModel.expandReflection() }
                            } else {
                                viewModel.prompt = editableExpanded
                                Task { await viewModel.generateImage() }
                            }
                        } label: {
                            Text(
                                viewModel.isExpanding ? "Reading…"
                                : viewModel.isLoading ? "Generating…"
                                : viewModel.generatedImageURL != nil ? "Regenerate"
                                : viewModel.expandedPrompt != nil ? "Generate Image"
                                : "Continue"
                            )
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isExpanding || viewModel.isLoading
                                    ? Color.blue.opacity(0.4)
                                    : Color.blue
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(
                            reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isExpanding || viewModel.isLoading
                        )

                        // Expanded prompt — editable before generating
                        if viewModel.expandedPrompt != nil {
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

                        // Loading state
                        if viewModel.isExpanding || viewModel.isLoading {
                            VStack(spacing: 14) {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(1.3)
                                    .tint(.secondary)
                                Text(viewModel.isExpanding ? "Reading your reflection…" : "Generating your image…")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        // Generated image + post-image reflection
                        if let url = viewModel.generatedImageURL, !viewModel.isExpanding, !viewModel.isLoading {
                            VStack(alignment: .leading, spacing: 20) {

                                // Image
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Your Image")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.primary)

                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .empty:
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(Color(.secondarySystemBackground))
                                                .overlay(ProgressView())
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 280)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 280)
                                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        case .failure:
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(Color(.secondarySystemBackground))
                                                .overlay(
                                                    VStack(spacing: 8) {
                                                        Image(systemName: "exclamationmark.triangle")
                                                        Text("Failed to load image")
                                                            .font(.caption)
                                                    }
                                                    .foregroundColor(.secondary)
                                                )
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 280)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }

                                // Post-image reflection
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("What do you notice about this image? What might it mean for you?")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)

                                    ZStack(alignment: .topLeading) {
                                        if postImageReflection.isEmpty {
                                            Text("I notice...")
                                                .font(.system(size: 15))
                                                .foregroundColor(Color(.placeholderText))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 13)
                                        }
                                        TextEditor(text: $postImageReflection)
                                            .font(.system(size: 15))
                                            .foregroundColor(.primary)
                                            .focused($isPostImageFocused)
                                            .frame(minHeight: 90)
                                            .scrollContentBackground(.hidden)
                                            .scrollDisabled(true)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                    }
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(
                                                isPostImageFocused ? Color.blue : Color(.systemGray4),
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                                Button {
                                    store.add(JournalEntry(
                                        imageURL: url,
                                        question: "What do you notice about this image? What might it mean for you?",
                                        reflectionText: postImageReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                            ? reflectionText
                                            : postImageReflection,
                                        concept: "The Unconscious Mind"
                                    ))
                                    savedToLibrary = true
                                    NavigationManager.shared.popToRoot = true
                                } label: {
                                    Text(savedToLibrary ? "Saved to Reflections" : "Save to Reflections")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(savedToLibrary ? .secondary : .blue)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(savedToLibrary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemBackground))
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarHidden(true)
        .onChange(of: viewModel.expandedPrompt) { _, val in
            if let v = val { editableExpanded = v }
        }
    }
}

#Preview {
    NavigationStack {
        UnconsciousMindView()
            .environmentObject(SessionManager.shared)
    }
}
