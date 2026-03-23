// Features/History/HistoryViewModel.swift
import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {

    // MARK: - Published State

    @Published var images: [ImageModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""

    // MARK: - Dependencies

    private let apiClient = APIClient.shared

    // MARK: - Computed

    var filteredImages: [ImageModel] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return images
        }
        return images.filter {
            $0.prompt.localizedCaseInsensitiveContains(searchText)
        }
    }

    // Group images by date (day) for sectioned list
    var groupedImages: [(String, [ImageModel])] {
        let grouped = Dictionary(grouping: filteredImages) { image -> String in
            image.createdAt.formatted(.dateTime.year().month(.wide).day())
        }
        return grouped.sorted { a, b in
            // Sort sections newest first
            guard
                let firstA = a.1.first?.createdAt,
                let firstB = b.1.first?.createdAt
            else { return false }
            return firstA > firstB
        }
    }

    // MARK: - Load

    func loadHistory() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            // Load up to 100 most recent for history view
            images = try await apiClient.getImages(page: 1, limit: 100)
        } catch APIError.unauthorized {
            SessionManager.shared.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadHistory()
    }
}
