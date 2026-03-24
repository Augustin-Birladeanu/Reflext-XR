// Core/Networking/APIClient.swift
import Foundation

// MARK: - APIError

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case insufficientCredits
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:          return "Invalid request URL."
        case .noData:              return "No data received from server."
        case .decodingError(let e): return "Data parsing error: \(e.localizedDescription)"
        case .serverError(let msg): return msg
        case .unauthorized:        return "Session expired. Please log in again."
        case .insufficientCredits: return "Not enough credits. Purchase more to continue."
        case .unknown:             return "An unexpected error occurred."
        }
    }
}

// MARK: - APIClient

final class APIClient {

    static let shared = APIClient()
    private init() {}

    // Update this to your backend URL (use your machine's LAN IP for device testing)
    private let baseURL = "http://localhost:3000/api"

    // MARK: - JSON Decoder

    private lazy var decoder: JSONDecoder = {
        let d = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = formatter.date(from: str) { return date }
            // Fallback without fractional seconds
            let fallback = ISO8601DateFormatter()
            if let date = fallback.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return d
    }()

    // MARK: - Auth Token

    private var authToken: String? {
        get { KeychainService.shared.getToken() }
    }

    // MARK: - Core Request

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        requiresAuth: Bool = true,
        timeoutInterval: TimeInterval = 60
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        if requiresAuth {
            guard let token = authToken else { throw APIError.unauthorized }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch httpResponse.statusCode {
        case 401:
            throw APIError.unauthorized
        case 402:
            throw APIError.insufficientCredits
        case 200...299:
            break
        default:
            // Try to extract server error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMsg = json["error"] as? String {
                throw APIError.serverError(errorMsg)
            }
            throw APIError.serverError("Server returned status \(httpResponse.statusCode)")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Auth

    func register(email: String, password: String) async throws -> AuthData {
        let response: AuthResponse = try await request(
            path: "/users/register",
            method: "POST",
            body: ["email": email, "password": password],
            requiresAuth: false
        )
        guard let data = response.data else {
            throw APIError.serverError(response.error ?? "Registration failed.")
        }
        return data
    }

    func login(email: String, password: String) async throws -> AuthData {
        let response: AuthResponse = try await request(
            path: "/users/login",
            method: "POST",
            body: ["email": email, "password": password],
            requiresAuth: false
        )
        guard let data = response.data else {
            throw APIError.serverError(response.error ?? "Login failed.")
        }
        return data
    }

    func getMe() async throws -> UserProfile {
        let response: UserProfileResponse = try await request(path: "/users/me")
        guard let data = response.data else {
            throw APIError.serverError(response.error ?? "Failed to load profile.")
        }
        return data
    }

    // MARK: - Images

    func generateImage(prompt: String) async throws -> GeneratedImageData {
        let response: GenerateImageResponse = try await request(
            path: "/images/generate",
            method: "POST",
            body: ["prompt": prompt],
            timeoutInterval: 120
        )
        guard let data = response.data else {
            throw APIError.serverError(response.error ?? "Image generation failed.")
        }
        return data
    }

    func getImages(page: Int = 1, limit: Int = 20) async throws -> [ImageModel] {
        let response: ImagesListResponse = try await request(
            path: "/images?page=\(page)&limit=\(limit)"
        )
        return response.data ?? []
    }

    func getImage(id: String) async throws -> ImageModel {
        let response: SingleImageResponse = try await request(path: "/images/\(id)")
        guard let data = response.data else {
            throw APIError.serverError(response.error ?? "Image not found.")
        }
        return data
    }

    func deleteImage(id: String) async throws {
        let _: DeleteResponse = try await request(
            path: "/images/\(id)",
            method: "DELETE"
        )
    }

}

// MARK: - UserProfileResponse (helper)

private struct UserProfileResponse: Codable {
    let success: Bool
    let data: UserProfile?
    let error: String?
}
