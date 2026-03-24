// Core/Navigation/NavigationManager.swift

import Combine
import SwiftUI

final class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    let objectWillChange = ObservableObjectPublisher()

    var path = NavigationPath() {
        willSet { objectWillChange.send() }
    }

    var popToRoot = false {
        willSet { objectWillChange.send() }
    }
}
