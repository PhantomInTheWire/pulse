//
//  PulseApp.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI

@main
struct PulseApp: App {
    init() {
        // Initialize the contribution manager to start periodic fetching
        _ = ContributionManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
