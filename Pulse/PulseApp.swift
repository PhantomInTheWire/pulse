//
//  PulseApp.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI

@main
struct PulseApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Initialize the contribution manager to start periodic fetching
        _ = ContributionManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .onChange(of: scenePhase) { _, newPhase in
            // Timers don't fire while suspended on iOS; refresh on return to foreground
            if newPhase == .active {
                Task { await ContributionManager.shared.fetchContributionsIfNeeded() }
            }
            #if os(iOS)
            if newPhase == .background {
                ContributionManager.shared.scheduleBackgroundRefresh()
            }
            #endif
        }
    }
}
