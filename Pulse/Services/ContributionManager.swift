//
//  ContributionManager.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import Combine
import Foundation
import WidgetKit

class ContributionManager: ObservableObject {
    static let shared = ContributionManager()

    @Published var isFetching = false
    @Published var lastUpdated: Date?
    @Published var lastError: String?

    private let sharedData = SharedDataManager.shared
    private let authService = GitHubAuthService.shared
    private var fetchTimer: Timer?

    private init() {
        lastUpdated = sharedData.getLastUpdatedDate()
        setupPeriodicFetching()
    }

    // MARK: - Public Methods

    func fetchContributionsIfNeeded() async {
        guard authService.isAuthenticated, !sharedData.isDataFresh() else { return }
        await fetchContributions()
    }

    func fetchContributions() async {
        guard authService.isAuthenticated else {
            print("Cannot fetch contributions: not authenticated")
            return
        }

        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        do {
            let contributions = try await authService.fetchContributions()

            // user may have disconnected while the request was in flight;
            // don't resurrect shared auth state after logout
            guard authService.isAuthenticated else { return }

            sharedData.saveContributions(contributions)
            sharedData.setAuthenticated(true)
            lastUpdated = Date()
            lastError = nil
            updateWidgetTimeline()
        } catch {
            if case AuthError.tokenRevoked = error {
                authService.logout()
                return
            }
            lastError = error.localizedDescription
            print("Failed to fetch contributions: \(error.localizedDescription)")
        }
    }

    // MARK: - Periodic Fetching

    private func setupPeriodicFetching() {
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 2 * 60 * 60, repeats: true) { [weak self] _ in
            Task { await self?.fetchContributionsIfNeeded() }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            Task { await self.fetchContributionsIfNeeded() }
        }
    }

    // MARK: - Widget Updates

    private func updateWidgetTimeline() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Authentication State Management

    func handleAuthenticationChange() async {
        if authService.isAuthenticated {
            await fetchContributions()
        } else {
            sharedData.setAuthenticated(false)
            sharedData.clearAllData()
            updateWidgetTimeline()
        }
    }

    deinit {
        fetchTimer?.invalidate()
    }
}
