// Features/History/HistoryView.swift
import SwiftUI

struct HistoryView: View {

    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.images.isEmpty {
                    loadingView
                } else if viewModel.filteredImages.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search prompts"
            )
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                if viewModel.images.isEmpty {
                    await viewModel.loadHistory()
                }
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

    private var historyList: some View {
        List {
            ForEach(viewModel.groupedImages, id: \.0) { section, items in
                Section(header: Text(section).textCase(.none)) {
                    ForEach(items) { image in
                        HistoryRow(image: image)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.4)
            Text("Loading history…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.searchText.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.4))

            Text(viewModel.searchText.isEmpty ? "No history yet" : "No results found")
                .font(.title3.weight(.semibold))

            Text(viewModel.searchText.isEmpty
                 ? "Prompts from your generated images will appear here."
                 : "Try a different search term.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - History Row

struct HistoryRow: View {

    let image: ImageModel

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            AsyncImage(url: URL(string: image.url)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                        .overlay(ProgressView().scaleEffect(0.6))

                case .success(let img):
                    img
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )

                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 56, height: 56)
            .clipped()

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(image.prompt)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                Text(image.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
            .foregroundColor(Color(UIColor.tertiaryLabel))        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}
