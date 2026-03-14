// Core/Models/ImageModel.swift
import Foundation

struct ImageModel: Identifiable, Codable, Equatable {
    let id: String
    let prompt: String
    let url: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case prompt
        case url
        case createdAt
    }
}

// MARK: - API Response Wrappers

struct GenerateImageResponse: Codable {
    let success: Bool
    let data: GeneratedImageData?
    let error: String?
}

struct GeneratedImageData: Codable {
    let id: String
    let prompt: String
    let url: String
    let createdAt: Date
    let creditsRemaining: Int
    let revisedPrompt: String?
}

struct ImagesListResponse: Codable {
    let success: Bool
    let data: [ImageModel]?
    let error: String?
    let pagination: Pagination?
}

struct SingleImageResponse: Codable {
    let success: Bool
    let data: ImageModel?
    let error: String?
}

struct DeleteResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

// MARK: - Auth Response Wrappers

struct AuthResponse: Codable {
    let success: Bool
    let data: AuthData?
    let error: String?
}

struct AuthData: Codable {
    let token: String
    let user: UserProfile
}

struct UserProfile: Codable {
    let id: String
    let email: String
    let credits: Int
    let createdAt: Date
}
