// Features/GenerateImage/GenerateView.swift
import SwiftUI

struct GenerateView: View {

    @StateObject private var viewModel = GenerateViewModel()
    @EnvironmentObject private var session: SessionManager
    @FocusState private var isPromptFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Credits badge
                    if let credits = session.currentUser?.credits {
                        CreditsView(credits: credits)
                    }

                    // Prompt input
                    promptSection

                    // Generate button
                    generateButton

                    // Result
                    if viewModel.isLoading {
                        loadingSection
                    } else if let url = viewModel.generatedImageURL {
                        imagePreviewSection(url: url)
                    }

                    // Error
                    if let error = viewModel.errorMessage {
                        errorBanner(message: error)
                    }

                    // Success
                    if let success = viewModel.successMessage, viewModel.generatedImageURL != nil {
                        successBanner(message: success)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Inscape")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isPromptFocused = false }
                }
            }
        }
    }

    // MARK: - Subviews

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Describe your image")
                .font(.headline)
                .foregroundColor(.primary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPromptFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                    )

                TextEditor(text: $viewModel.prompt)
                    .focused($isPromptFocused)
                    .frame(minHeight: 100, maxHeight: 180)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)

                if viewModel.prompt.isEmpty {
                    Text("e.g. A futuristic city at sunset, cinematic lighting, 8K...")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 120)

            HStack {
                Spacer()
                Text("\(viewModel.prompt.count)/1000")
                    .font(.caption2)
                    .foregroundColor(viewModel.prompt.count > 900 ? .orange : .secondary)
            }
        }
    }

    private var generateButton: some View {
        Button {
            isPromptFocused = false
            Task { await viewModel.generateImage() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text("Generate Image")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.canGenerate ? Color.accentColor : Color.secondary.opacity(0.3))
            .foregroundColor(viewModel.canGenerate ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!viewModel.canGenerate)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canGenerate)
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.4)
                .tint(.accentColor)

            Text("Generating your image…")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("This may take up to 30 seconds")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func imagePreviewSection(url: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated Image")
                .font(.headline)

            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(ProgressView())
                        .frame(height: 320)

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))

                case .failure:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                Text("Failed to load image")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        )
                        .frame(height: 320)

                @unknown default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.4), value: url)

            // Action row
            HStack(spacing: 12) {
                ShareLink(item: URL(string: url)!) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    viewModel.reset()
                } label: {
                    Label("New", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .font(.subheadline.weight(.medium))
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Button { viewModel.clearError() } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func successBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(14)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Credits Badge

struct CreditsView: View {
    let credits: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.caption.weight(.bold))
            Text("\(credits) \(credits == 1 ? "credit" : "credits") remaining")
                .font(.subheadline.weight(.medium))
            Spacer()
            if credits == 0 {
                Text("Purchase more →")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.accentColor)
            }
        }
        .foregroundColor(credits > 0 ? .primary : .orange)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(credits > 0 ? Color(.secondarySystemBackground) : Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    GenerateView()
        .environmentObject(SessionManager.shared)
}
