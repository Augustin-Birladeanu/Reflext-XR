// CreateView.swift

import SwiftUI

struct CreateView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navManager: NavigationManager

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Custom Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Text("Create")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Heading
                Text("How would you like to\ncreate today?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)

                // MARK: Card 1 — Enter a Prompt
                NavigationLink(destination: FreeTextPromptView()) {
                    CreateCard(imageName: "home_create") {
                        Text("Enter a Prompt")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.darkGray))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 24)
                    }
                }
                .buttonStyle(.plain)

                // MARK: Card 2 — Select from Options
                NavigationLink(destination: ConceptsView()) {
                    CreateCard(imageName: "createUI-options") {
                        Text("Select from Options")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.darkGray))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 24)
                    }
                }
                .buttonStyle(.plain)

                // MARK: Card 3 — Select from Images
                NavigationLink(destination: SelectFromImagesView()) {
                    CreateCard(imageName: "createUI-select") {
                        Text("Select from Images")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.darkGray))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 24)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        } // end outer VStack
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .onChange(of: navManager.popToRoot) { _, popping in
            if popping { dismiss() }
        }
    }
}

// MARK: - Reusable Card Container

struct CreateCard<Overlay: View>: View {
    let imageName: String
    @ViewBuilder let overlay: () -> Overlay

    var body: some View {
        ZStack {
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }

            overlay()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        CreateView()
            .environmentObject(SessionManager.shared)
    }
}
