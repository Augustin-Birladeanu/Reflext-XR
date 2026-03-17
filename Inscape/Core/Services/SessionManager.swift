// Core/Services/SessionManager.swift
import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {

    static let shared = SessionManager()
    private init() { loadStoredUser() }

    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false

    private let userKey = "inscape_current_user"

    func signIn(authData: AuthData) {
        KeychainService.shared.saveToken(authData.token)
        currentUser = authData.user
        isAuthenticated = true
        persistUser(authData.user)
    }

    func signOut() {
        KeychainService.shared.deleteToken()
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    func updateCredits(_ newCredits: Int) {
        guard let user = currentUser else { return }
        // Rebuild with updated credits
        currentUser = UserProfile(
            id: user.id,
            email: user.email,
            credits: newCredits,
            createdAt: user.createdAt
        )
        if let user = currentUser { persistUser(user) }
    }

    private func persistUser(_ user: UserProfile) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    private func loadStoredUser() {
        guard let data = UserDefaults.standard.data(forKey: userKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let user = try? decoder.decode(UserProfile.self, from: data),
           KeychainService.shared.getToken() != nil {
            currentUser = user
            isAuthenticated = true
        }
    }
}
