// ImageResultView.swift

import SwiftUI

struct ImageResultView: View {

    let prompt: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GenerateViewModel()
    @State private var selectedImageURL: String? = nil
    @State private var additionalPrompt: String = ""
    @State private var navigateToReflect = false

    // TODO: set back to 4 after testing
    private let imageCount = 1

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var effectivePrompt: String {
        let additional = additionalPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if additional.isEmpty {
            return prompt
        }
        return "\(prompt). \(additional)"
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
                Text("Response")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // MARK: Content
            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.4)
                        .tint(.primary)
                    Text("Generating your images…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        // MARK: Grid header row
                        HStack {
                            Text("Select an image or")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                            Button {
                                viewModel.generatedImageURLs = []
                                viewModel.prompt = effectivePrompt
                                Task { await viewModel.generateImages(count: imageCount) }
                            } label: {
                                Text("Regenerate")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.blue, lineWidth: 1.5)
                                    )
                            }
                        }

                        // MARK: 2x2 Image Grid
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(0..<imageCount, id: \.self) { index in
                                if index < viewModel.generatedImageURLs.count {
                                    let url = viewModel.generatedImageURLs[index]
                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img
                                                .resizable()
                                                .scaledToFill()
                                        case .failure:
                                            Color(.secondarySystemBackground)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.secondary)
                                                )
                                        default:
                                            Color(.secondarySystemBackground)
                                                .overlay(ProgressView())
                                        }
                                    }
                                    .aspectRatio(1, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay {
                                        if selectedImageURL == url {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color.blue, lineWidth: 3)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedImageURL = url
                                        navigateToReflect = true
                                    }
                                } else {
                                    Color(.secondarySystemBackground)
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(ProgressView())
                                }
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

                        // MARK: Prompt Section
                        // MARK: Prompt Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .center) {
                                Text("Prompt")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button { dismiss() } label: {
                                    Text("Edit Prompt")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                .stroke(Color.blue, lineWidth: 1.5)
                                        )
                                }
                            }

                            Text(prompt)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.primary, lineWidth: 1.5)
                                )
                        }

                        // MARK: Additional Prompt Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Additional Prompt")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Modify the existing change by typing what changes to make the image.")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)

                            ZStack(alignment: .bottomTrailing) {
                                ZStack(alignment: .topLeading) {
                                    if additionalPrompt.isEmpty {
                                        Text("Add more details to refine the image…")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(.placeholderText))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                    }
                                    TextEditor(text: $additionalPrompt)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                        .frame(minHeight: 80)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .padding(.bottom, 28)
                                }

                                Button {
                                    viewModel.generatedImageURLs = []
                                    viewModel.prompt = effectivePrompt
                                    Task { await viewModel.generateImages(count: imageCount) }
                                } label: {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(12)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.primary, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .onAppear {
            guard viewModel.generatedImageURLs.isEmpty && !viewModel.isLoading else { return }
            viewModel.prompt = prompt
            Task { await viewModel.generateImages(count: imageCount) }
        }
        .navigationDestination(isPresented: $navigateToReflect) {
            if let url = selectedImageURL {
                ResponseDetailView(imageURL: url, prompt: prompt, concept: "")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ImageResultView(prompt: "a lion defending his land, teeth bared, wind blowing his proud mane")
            .environmentObject(SessionManager.shared)
    }
}
