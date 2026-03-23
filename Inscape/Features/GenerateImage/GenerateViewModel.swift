// Features/GenerateImage/GenerateViewModel.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class GenerateViewModel: ObservableObject {

    // MARK: - Published State

    @Published var prompt: String = ""
    @Published var generatedImageURL: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var creditsRemaining: Int?

    // MARK: - Dependencies

    private let apiClient = APIClient.shared
    private let session = SessionManager.shared

    // MARK: - Computed

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    // MARK: - Actions

    func generateImage() async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            errorMessage = "Please enter a prompt first."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let result = try await apiClient.generateImage(prompt: trimmedPrompt)
            generatedImageURL = result.url
            creditsRemaining = result.creditsRemaining
            session.updateCredits(result.creditsRemaining)

            if let revised = result.revisedPrompt, revised != trimmedPrompt {
                successMessage = "Image generated! (Prompt slightly revised by AI)"
            } else {
                successMessage = "Image generated successfully!"
            }
        } catch APIError.insufficientCredits {
            errorMessage = "You've run out of credits. Purchase more to continue generating images."
        } catch APIError.unauthorized {
            session.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }

    func reset() {
        prompt = ""
        generatedImageURL = nil
        errorMessage = nil
        successMessage = nil
    }
}
