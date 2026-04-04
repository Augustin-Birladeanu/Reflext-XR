// SelfCompassionView.swift

import SwiftUI

struct SelfCompassionView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GenerateViewModel()
    @State private var reflectionText: String = ""
    @State private var editableExpanded: String = ""
    @State private var savedToLibrary = false
    @FocusState private var isReflectionFocused: Bool

    private let store = JournalStore.shared

    private let practices = [
        "Imagine what you'd say to a loved one",
        "Reframe harsh self-critical thoughts",
        "Acknowledge your pain without judgment",
        "Write a compassionate letter to yourself",
        "Treat your energy as something valuable",
        "Forgive yourself for mistakes and missteps",
        "Keep a self-compassion journal"
    ]

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
                Text("Self-Compassion")
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

                    // Full-width hero image
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

                            Text("Self-compassion is the practice of treating yourself with the same warmth and care you would extend to others. Suffering and imperfection are part of the shared human experience—not something you are alone in.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Practices
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Practices")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(practices, id: \.self) { practice in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("•")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.blue)
                                            .frame(width: 14)
                                        Text(practice)
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }

                        // Reflection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reflection")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)

                            Text("We invite you to think about a compassionate statement for yourself.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            ZStack(alignment: .topLeading) {
                                if reflectionText.isEmpty {
                                    Text("I am... / I bring to others...")
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
                                        isReflectionFocused
                                            ? Color.blue
                                            : Color(.systemGray4),
                                        lineWidth: 1
                                    )
                            )
                        }

                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

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
                        } else if let url = viewModel.generatedImageURL {
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

                                Button {
                                    store.add(JournalEntry(
                                        imageURL: url,
                                        question: "We invite you to think about a compassionate statement for yourself.",
                                        reflectionText: reflectionText,
                                        concept: "Self-Compassion"
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

                        // Generate / Regenerate button
                        Button {
                            isReflectionFocused = false
                            if viewModel.generatedImageURL != nil {
                                // Regenerate: start over
                                savedToLibrary = false
                                viewModel.generatedImageURL = nil
                                viewModel.expandedPrompt = nil
                                editableExpanded = ""
                                viewModel.prompt = reflectionText
                                Task { await viewModel.expandReflection() }
                            } else if viewModel.expandedPrompt == nil {
                                // Phase 1: expand the reflection
                                viewModel.prompt = reflectionText
                                Task { await viewModel.expandReflection() }
                            } else {
                                // Phase 2: generate from the (possibly edited) expanded prompt
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
        SelfCompassionView()
            .environmentObject(SessionManager.shared)
    }
}
