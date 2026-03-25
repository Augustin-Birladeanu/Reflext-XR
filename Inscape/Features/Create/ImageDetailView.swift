// ResponseDetailView.swift

import SwiftUI

struct ResponseDetailView: View {
    let imageURL: String
    let prompt: String
    let concept: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navManager: NavigationManager

    @State private var insights: String = ""
    @State private var isLoadingInsights = true
    @State private var insightsError: String? = nil

    @State private var navigateToReflect = false
    @State private var isSaving = false
    @State private var savedToast = false
    @State private var addedToLibraryToast = false
    @State private var shareItem: URL? = nil
    @State private var showShareSheet = false

    private let apiClient = APIClient.shared

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
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: Image
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let img):
                            img
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        case .failure:
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                                .frame(height: 300)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                )
                        default:
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                                .frame(height: 300)
                                .overlay(ProgressView())
                        }
                    }

                    // MARK: Prompt Box
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prompt")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(prompt)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.primary, lineWidth: 1.5)
                            )
                    }

                    // MARK: Insights Box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Insights")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        if isLoadingInsights {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Generating insights…")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.primary, lineWidth: 1.5)
                            )
                        } else if let error = insightsError {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.primary, lineWidth: 1.5)
                                )
                        } else {
                            Text(insights)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.primary, lineWidth: 1.5)
                                )
                        }
                    }

                    // MARK: Reflect Button
                    Button { navigateToReflect = true } label: {
                        Text("Reflect")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    // MARK: Action Buttons 2x2 Grid
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            ActionButton(label: "Save", icon: "square.and.arrow.down") {
                                saveToPhotoLibrary()
                            }
                            ActionButton(label: "Add to Library", icon: "books.vertical") {
                                addedToLibraryToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    addedToLibraryToast = false
                                }
                            }
                        }
                        HStack(spacing: 10) {
                            ActionButton(label: "Regenerate", icon: "arrow.clockwise") {
                                dismiss()
                            }
                            ActionButton(label: "Share", icon: "square.and.arrow.up") {
                                fetchAndShare()
                            }
                        }
                    }

                    // Toast messages
                    if savedToast {
                        Text("Saved to Photos")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    if addedToLibraryToast {
                        Text("Added to your library — view it in Reflect > Images")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let url = shareItem {
                ShareSheet(activityItems: [url])
            }
        }
        .onChange(of: navManager.popToRoot) { _, popping in
            if popping { dismiss() }
        }
        .onAppear {
            Task { await loadInsights() }
        }
        .navigationDestination(isPresented: $navigateToReflect) {
            ReflectView(imageURL: imageURL, concept: concept)
        }
    }

    // MARK: - Insights

    private func loadInsights() async {
        isLoadingInsights = true
        insightsError = nil
        do {
            insights = try await apiClient.generateInsights(prompt: prompt)
        } catch {
            insightsError = "Could not load insights."
        }
        isLoadingInsights = false
    }

    // MARK: - Save to Photos

    private func saveToPhotoLibrary() {
        guard let url = URL(string: imageURL) else { return }
        isSaving = true
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                isSaving = false
                guard let data = data, let uiImage = UIImage(data: data) else { return }
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                savedToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { savedToast = false }
            }
        }.resume()
    }

    // MARK: - Share

    private func fetchAndShare() {
        guard let url = URL(string: imageURL) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data,
                      let uiImage = UIImage(data: data),
                      let pngData = uiImage.pngData() else { return }
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("inscape_image.png")
                try? pngData.write(to: tmpURL)
                shareItem = tmpURL
                showShareSheet = true
            }
        }.resume()
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.blue, lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ResponseDetailView(
            imageURL: "",
            prompt: "A lion defending his land, teeth bared, wind blowing his proud mane",
            concept: ""
        )
        .environmentObject(NavigationManager())
    }
}
