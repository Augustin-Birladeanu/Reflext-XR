// InscapeApp.swift
// Place this in the root of your Xcode project.

import SwiftUI

@main
struct InscapeApp: App {

    @StateObject private var session = SessionManager.shared
    @StateObject private var navManager = NavigationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .environmentObject(navManager)
                .task {
                    await session.validateSession()
                }
        }
    }
}
