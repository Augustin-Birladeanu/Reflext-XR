// Core/Utils/AuthView.swift
import SwiftUI
import Combine

struct AuthView: View {

    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {

                    // Logo / Wordmark
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Inscape")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("Generate stunning AI images")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Segmented picker
                    Picker("Mode", selection: $viewModel.isLoginMode) {
                        Text("Sign In").tag(true)
                        Text("Create Account").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $viewModel.password)
                            .textContentType(viewModel.isLoginMode ? .password : .newPassword)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    // Submit button
                    Button {
                        Task { await viewModel.submit(session: session) }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(viewModel.isLoginMode ? "Sign In" : "Create Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)
                    .padding(.horizontal, 24)

                    if !viewModel.isLoginMode {
                        Text("By creating an account, you agree to our Terms of Service and Privacy Policy.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 40)
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoginMode)
            .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
        }
    }
}

// MARK: - AuthViewModel

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoginMode: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var isFormValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedEmail.contains("@") && trimmedPass.count >= 8
    }

    private let apiClient = APIClient.shared

    func submit(session: SessionManager) async {
        isLoading = true
        errorMessage = nil

        do {
            let authData: AuthData
            if isLoginMode {
                authData = try await apiClient.login(email: email.lowercased(), password: password)
            } else {
                authData = try await apiClient.register(email: email.lowercased(), password: password)
            }
            KeychainService.shared.saveToken(authData.token)
            session.signIn(authData: authData)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    AuthView()
        .environmentObject(SessionManager.shared)
}
