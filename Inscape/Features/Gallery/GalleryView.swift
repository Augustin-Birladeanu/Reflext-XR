// Features/Gallery/GalleryView.swift
import SwiftUI

struct GalleryView: View {

    @StateObject private var viewModel = GalleryViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.images.isEmpty {
                    loadingView
                } else if viewModel.images.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    gridView
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading && !viewModel.images.isEmpty {
                        ProgressView()
                    }
                }
            }
            .refreshable {
                await viewModel.loadImages()
            }
            .task {
                if viewModel.images.isEmpty {
                    await viewModel.loadImages()
                }
            }
            .sheet(item: $viewModel.selectedImage) { image in
                ImageDetailView(image: image) {
                    viewModel.confirmDelete(image)
                }
            }
            .confirmationDialog(
                "Delete Image",
                isPresented: $viewModel.showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteImage() }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
            } message: {
                Text("This image will be permanently deleted.")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Subviews

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.images) { image in
                    GalleryCell(image: image)
                        .onTapGesture {
                            viewModel.selectedImage = image
                        }
                        .task {
                            await viewModel.loadMoreIfNeeded(currentItem: image)
                        }
                }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.vertical, 20)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Loading gallery…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No images yet")
                .font(.title3.weight(.semibold))
            Text("Generate your first image to see it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Gallery Cell

struct GalleryCell: View {

    let image: ImageModel

    var body: some View {
        AsyncImage(url: URL(string: image.url)) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color(.secondarySystemBackground))
                    .overlay(ProgressView().scaleEffect(0.7))

            case .success(let img):
                img
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()

            case .failure:
                Rectangle()
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )

            @unknown default:
                EmptyView()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
    }
}

// MARK: - Image Detail Sheet

struct ImageDetailView: View {

    let image: ImageModel
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AsyncImage(url: URL(string: image.url)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                                .frame(height: 360)
                                .overlay(ProgressView())

                        case .success(let img):
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)

                        case .failure:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                                .frame(height: 320)
                                .overlay(
                                    Label("Failed to load", systemImage: "exclamationmark.triangle")
                                        .foregroundColor(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Prompt")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text(image.prompt)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)

                    Text(image.createdAt.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)

                    // Action buttons
                    HStack(spacing: 12) {
                        if let url = URL(string: image.url) {
                            ShareLink(item: url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        Button(role: .destructive) {
                            dismiss()
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Image Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    GalleryView()
}
