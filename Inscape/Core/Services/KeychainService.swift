// Core/Services/KeychainService.swift
import Foundation
import Security

final class KeychainService {

    static let shared = KeychainService()
    private init() {}

    private let tokenKey = "inscape_auth_token"
    private let userIdKey = "inscape_user_id"

    // MARK: - Token

    @discardableResult
    func saveToken(_ token: String) -> Bool {
        return save(key: tokenKey, value: token)
    }

    func getToken() -> String? {
        return get(key: tokenKey)
    }

    func deleteToken() {
        delete(key: tokenKey)
    }

    // MARK: - Generic Keychain

    private func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func get(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
