// InscapeApp.swift
// Place this in the root of your Xcode project.

import SwiftUI

@main
struct InscapeApp: App {

    @StateObject private var session = SessionManager.shared
    @StateObject private var navManager = NavigationManager.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(session)
                    .environmentObject(navManager)
                    .task {
                        await session.validateSession()
                    }

                if showSplash {
                    SplashScreenView {
                        showSplash = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSplash)
        }
    }
}
