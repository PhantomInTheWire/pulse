//
//  ContentView.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var authService = GitHubAuthService.shared

    var body: some View {
        VStack(spacing: 20) {
            headerView

            switch authService.authState {
            case .notAuthenticated, .awaitingUser, .polling:
                LoginView(authService: authService)
            case .authenticated:
                HomeView(authService: authService)
            case .error:
                ErrorView(message: authService.errorMessage ?? "Unknown error") {
                    authService.startDeviceFlow()
                }
            }

            Spacer()
        }
        .padding()
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Pulse")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("GitHub Contribution Heatmap Widget")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
