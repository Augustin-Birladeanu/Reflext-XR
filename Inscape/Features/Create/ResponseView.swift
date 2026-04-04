// ResponseView.swift

import SwiftUI

struct ResponseView: View {
    let prompt: String
    let concept: String
    let subtitle: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navManager: NavigationManager
    @StateObject private var viewModel = GenerateViewModel()
    @State private var selectedImageURL: String? = nil
    @State private var navigateToReflect = false

    private let imageCount = 4

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
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
                Text("Response")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                // Balance spacer
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Concept subtitle
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

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
                    VStack(spacing: 12) {
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
                                    // Placeholder while this slot is still generating
                                    Color(.secondarySystemBackground)
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            viewModel.isLoading ? AnyView(ProgressView()) : AnyView(EmptyView())
                                        )
                                }
                            }
                        }

                        Text("Select an image")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .onChange(of: navManager.popToRoot) { _, popping in
            if popping { dismiss() }
        }
        .onAppear {
            guard viewModel.generatedImageURLs.isEmpty && !viewModel.isLoading else { return }
            viewModel.prompt = prompt
            Task { await viewModel.generateImages(count: imageCount) }
        }
        .navigationDestination(isPresented: $navigateToReflect) {
            if let url = selectedImageURL {
                ReflectView(imageURL: url, concept: concept)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResponseView(
            prompt: "Design a safe container where sadness can rest without judgment.",
            concept: "A Safe Space",
            subtitle: "A safe space for emotions"
        )
        .environmentObject(SessionManager.shared)
    }
}
