// NeuroplasticityView.swift

import SwiftUI

struct NeuroplasticityView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GenerateViewModel()
    @State private var reflectionText: String = ""
    @State private var editableExpanded: String = ""
    @State private var savedToLibrary = false
    @FocusState private var isReflectionFocused: Bool

    private let store = JournalStore.shared

    private let bullets = [
        "New experiences = new brain paths",
        "Repetition strengthens connections",
        "Healing through expression — art lets you safely process emotions"
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
                Text("Neuroplasticity")
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

                            Text("Neuroplasticity is the brain's ability to adapt and change. The brain is constantly rewiring itself based on what you do, think, and feel. Every time you learn something new, practice a skill, or heal from an experience, your brain forms new connections.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Bullet list
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Key Ideas")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(bullets, id: \.self) { bullet in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("•")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.blue)
                                            .frame(width: 14)
                                        Text(bullet)
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }

                        // Reflection input
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reflection")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Write down a feeling or thought you'd like to change. Type words that represent what you'd like to feel or think instead.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            ZStack(alignment: .topLeading) {
                                if reflectionText.isEmpty {
                                    Text("I want to feel...")
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

                        // Loading / generated image
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
                                        question: "Write down a feeling or thought you'd like to change. Type words that represent what you'd like to feel or think instead.",
                                        reflectionText: reflectionText,
                                        concept: "Neuroplasticity"
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

                        // Generate button
                        Button {
                            isReflectionFocused = false
                            if viewModel.generatedImageURL != nil {
                                savedToLibrary = false
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
        NeuroplasticityView()
            .environmentObject(SessionManager.shared)
    }
}
