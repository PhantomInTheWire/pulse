//
//  ContributionManager.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import Foundation
import WidgetKit
import Combine

class ContributionManager: ObservableObject {
    static let shared = ContributionManager()
    
    private let sharedData = SharedDataManager.shared
    private let authService = GitHubAuthService.shared
    private var fetchTimer: Timer?
    
    private init() {
        setupPeriodicFetching()
    }
    
    // MARK: - Public Methods
    
    func fetchContributionsIfNeeded() async {
        // Only fetch if authenticated and data is stale
        guard authService.isAuthenticated,
              !sharedData.isDataFresh() else {
            return
        }
        
        await fetchContributions()
    }
    
    func fetchContributions() async {
        guard authService.isAuthenticated else {
            print("❌ Cannot fetch contributions: not authenticated")
            return
        }
        
        print("🔄 Starting contribution fetch...")
        
        do {
            let contributions = try await authService.fetchContributions()
            
            await MainActor.run {
                sharedData.saveContributions(contributions)
                sharedData.setAuthenticated(true)
                updateWidgetTimeline()
                print("✅ Contributions saved and widget updated successfully")
            }
        } catch {
            print("❌ Failed to fetch contributions: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
        }
    }
    
    // MARK: - Periodic Fetching
    
    private func setupPeriodicFetching() {
        // Fetch every 2 hours
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 2 * 60 * 60, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchContributionsIfNeeded()
            }
        }
        
        // Initial fetch after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            Task {
                await self.fetchContributionsIfNeeded()
            }
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
