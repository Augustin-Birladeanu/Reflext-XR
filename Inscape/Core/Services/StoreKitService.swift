// Core/Services/StoreKitService.swift
// StoreKit integration scaffold — ready for full implementation.
// Connect product IDs below to your App Store Connect in-app purchase setup.

import Foundation
import StoreKit
import Combine

// MARK: - Credit Packages

struct CreditPackage: Identifiable {
    let id: String          // StoreKit product ID
    let credits: Int
    let displayName: String
    let description: String
    var product: Product?   // Populated after StoreKit fetch
}

// MARK: - StoreKitService

@MainActor
final class StoreKitService: ObservableObject {

    static let shared = StoreKitService()
    private init() {}

    // MARK: - Credit package definitions
    // Replace product IDs with your App Store Connect in-app purchase IDs.
    @Published var packages: [CreditPackage] = [
        CreditPackage(id: "com.inscape.credits.10",  credits: 10,  displayName: "Starter",    description: "10 image credits"),
        CreditPackage(id: "com.inscape.credits.50",  credits: 50,  displayName: "Creator",    description: "50 image credits"),
        CreditPackage(id: "com.inscape.credits.150", credits: 150, displayName: "Pro",        description: "150 image credits"),
    ]

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var purchaseSuccessful: Bool = false

    private var purchaseUpdatesTask: Task<Void, Never>?

    // MARK: - Load Products from App Store

    func loadProducts() async {
        isLoading = true
        let productIDs = Set(packages.map { $0.id })

        do {
            let products = try await Product.products(for: productIDs)
            for product in products {
                if let idx = packages.firstIndex(where: { $0.id == product.id }) {
                    packages[idx].product = product
                }
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ package: CreditPackage) async {
        guard let product = package.product else {
            errorMessage = "Product not available. Please try again."
            return
        }

        isLoading = true

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                // TODO: Send transaction.id to backend to verify & credit the user
                await fulfillPurchase(credits: package.credits, transactionID: transaction.id)
                await transaction.finish()
                purchaseSuccessful = true

            case .userCancelled:
                break // User cancelled — no error shown

            case .pending:
                errorMessage = "Purchase is pending approval."

            @unknown default:
                errorMessage = "Unknown purchase result."
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            // Re-process all transactions
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
            }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    /// Called after a verified purchase — notifies backend to add credits.
    private func fulfillPurchase(credits: Int, transactionID: UInt64) async {
        // TODO: POST to /api/users/credits/add with { credits, transactionID }
        // and verify the Apple transaction server-side before awarding credits.
        // For now, optimistically update local session.
        let currentCredits = SessionManager.shared.currentUser?.credits ?? 0
        SessionManager.shared.updateCredits(currentCredits + credits)
    }
}

// MARK: - StoreError

enum StoreError: Error, LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        }
    }
}
