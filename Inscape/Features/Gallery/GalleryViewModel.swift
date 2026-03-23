// Features/Gallery/GalleryViewModel.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class GalleryViewModel: ObservableObject {

    // MARK: - Published State

    @Published var images: [ImageModel] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    @Published var selectedImage: ImageModel?
    @Published var showDeleteConfirm: Bool = false
    @Published var imageToDelete: ImageModel?

    // MARK: - Pagination

    private var currentPage: Int = 1
    private let pageLimit: Int = 20
    private var hasMorePages: Bool = true

    // MARK: - Dependencies

    private let apiClient = APIClient.shared

    // MARK: - Load

    func loadImages() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1
        hasMorePages = true

        do {
            let fetched = try await apiClient.getImages(page: 1, limit: pageLimit)
            images = fetched
            hasMorePages = fetched.count == pageLimit
        } catch APIError.unauthorized {
            SessionManager.shared.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMoreIfNeeded(currentItem: ImageModel) async {
        guard let lastImage = images.last,
              lastImage.id == currentItem.id,
              !isLoadingMore,
              hasMorePages else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let fetched = try await apiClient.getImages(page: currentPage, limit: pageLimit)
            images.append(contentsOf: fetched)
            hasMorePages = fetched.count == pageLimit
        } catch {
            currentPage -= 1 // revert on failure
        }

        isLoadingMore = false
    }

    // MARK: - Delete

    func confirmDelete(_ image: ImageModel) {
        imageToDelete = image
        showDeleteConfirm = true
    }

    func deleteImage() async {
        guard let image = imageToDelete else { return }
        showDeleteConfirm = false

        do {
            try await apiClient.deleteImage(id: image.id)
            images.removeAll { $0.id == image.id }
            if selectedImage?.id == image.id {
                selectedImage = nil
            }
        } catch {
            errorMessage = "Failed to delete image: \(error.localizedDescription)"
        }

        imageToDelete = nil
    }

    func cancelDelete() {
        imageToDelete = nil
        showDeleteConfirm = false
    }
}
