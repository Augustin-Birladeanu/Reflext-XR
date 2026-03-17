// ImageResultView.swift

import SwiftUI

struct ImageResultView: View {

    let prompt: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GenerateViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Text("Response")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // MARK: Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(1.4)
                                .tint(.primary)
                            Text("Generating your image…")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                    } else if let url = viewModel.generatedImageURL {
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                                    .overlay(ProgressView())
                                    .frame(height: 320)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 320)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            case .failure:
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle")
                                            Text("Failed to load image")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.secondary)
                                    )
                                    .frame(height: 320)
                            @unknown default:
                                EmptyView()
                            }
                        }

                        // Prompt display
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prompt")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(prompt)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        // Regenerate button
                        Button {
                            Task { await viewModel.generateImage() }
                        } label: {
                            Text("Regenerate")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.prompt = prompt
            Task { await viewModel.generateImage() }
        }
    }
}

#Preview {
    NavigationStack {
        ImageResultView(prompt: "a lion defending his land, teeth bared, wind blowing his proud mane")
            .environmentObject(SessionManager.shared)
    }
}
