// ContentView.swift
// Drop this into the root of your Xcode project (alongside InscapeApp.swift)

import SwiftUI
import StoreKit
struct ContentView: View {

    @EnvironmentObject private var session: SessionManager

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.isAuthenticated)
    }
}

// MARK: - Main Tab Bar

struct MainTabView: View {

    @EnvironmentObject private var session: SessionManager
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            GenerateView()
                .tabItem {
                    Label("Generate", systemImage: "sparkles")
                }
                .tag(0)

            GalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "photo.stack")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(3)
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {

    @EnvironmentObject private var session: SessionManager
    @StateObject private var storeKit = StoreKitService.shared

    var body: some View {
        NavigationStack {
            List {
                // User info section
                if let user = session.currentUser {
                    Section {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Text(user.email.prefix(1).uppercased())
                                        .font(.title2.weight(.bold))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(user.email)
                                    .font(.subheadline.weight(.medium))
                                Text("Member since \(user.createdAt.formatted(.dateTime.month().year()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Credits section
                    Section("Credits") {
                        HStack {
                            Label("Available credits", systemImage: "bolt.fill")
                            Spacer()
                            Text("\(user.credits)")
                                .font(.headline)
                                .foregroundColor(user.credits > 0 ? .primary : .orange)
                        }
                    }
                }

                // Purchase section
                Section("Purchase Credits") {
                    if storeKit.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        ForEach(storeKit.packages) { package in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(package.displayName)
                                        .font(.subheadline.weight(.semibold))
                                    Text(package.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if let product = package.product {
                                    Button {
                                        Task { await storeKit.purchase(package) }
                                    } label: {
                                        Text(product.displayPrice)
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color.accentColor)
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text("Unavailable")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        Button("Restore Purchases") {
                            Task { await storeKit.restorePurchases() }
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        session.signOut()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                await storeKit.loadProducts()
            }
            .alert("Purchase Error", isPresented: Binding(
                get: { storeKit.errorMessage != nil },
                set: { if !$0 { storeKit.errorMessage = nil } }
            )) {
                Button("OK") { storeKit.errorMessage = nil }
            } message: {
                Text(storeKit.errorMessage ?? "")
            }
            .alert("Purchase Successful!", isPresented: $storeKit.purchaseSuccessful) {
                Button("Great!") {}
            } message: {
                Text("Your credits have been added to your account.")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager.shared)
}
