//
//  SharedDataManager.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import Foundation

class SharedDataManager {
    static let shared = SharedDataManager()

    private let userDefaults: UserDefaults
    private let appGroupID = "group.com.karan.pulseShared"

    private struct Keys {
        static let contributions = "contributions"
        static let lastUpdated = "lastUpdated"
        static let isAuthenticated = "isAuthenticated"
    }

    private init() {
        // Use shared UserDefaults for app group communication
        print("🔍 Attempting to create shared UserDefaults with suite: \(appGroupID)")

        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            self.userDefaults = sharedDefaults
            print("✅ Successfully created shared UserDefaults for app group: \(appGroupID)")

            // Test write/read to verify it works
            sharedDefaults.set("test_value", forKey: "shared_test")
            if sharedDefaults.string(forKey: "shared_test") == "test_value" {
                print("✅ Shared UserDefaults read/write test passed")
                sharedDefaults.removeObject(forKey: "shared_test")
            } else {
                print("❌ Shared UserDefaults read/write test failed")
            }
        } else {
            print("❌ Failed to create shared UserDefaults for app group: \(appGroupID)")
            print("⚠️ Falling back to UserDefaults.standard - data sharing will not work!")
            self.userDefaults = UserDefaults.standard
        }
    }

    // MARK: - Contribution Data

    func saveContributions(_ contributions: ContributionResponse) {
        do {
            let data = try JSONEncoder().encode(contributions)
            userDefaults.set(data, forKey: Keys.contributions)
            userDefaults.set(Date(), forKey: Keys.lastUpdated)
            userDefaults.set(true, forKey: Keys.isAuthenticated)
            userDefaults.synchronize()
            print("✅ Saved \(contributions.weeks.count) weeks of contributions to UserDefaults")
        } catch {
            print("Failed to save contributions: \(error)")
        }
    }

    func retrieveContributions() -> ContributionResponse? {
        guard let data = userDefaults.data(forKey: Keys.contributions) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(ContributionResponse.self, from: data)
        } catch {
            print("Failed to decode contributions: \(error)")
            return nil
        }
    }

    func getLastUpdatedDate() -> Date? {
        userDefaults.object(forKey: Keys.lastUpdated) as? Date
    }

    func isDataFresh(maxAge: TimeInterval = 4 * 60 * 60) -> Bool {  // 4 hours default
        guard let lastUpdated = getLastUpdatedDate() else {
            return false
        }

        let timeSinceUpdate = Date().timeIntervalSince(lastUpdated)
        return timeSinceUpdate < maxAge
    }

    // MARK: - Authentication State

    func setAuthenticated(_ authenticated: Bool) {
        userDefaults.set(authenticated, forKey: Keys.isAuthenticated)
        userDefaults.synchronize()
    }

    func getIsAuthenticated() -> Bool {
        let isAuthenticated = userDefaults.bool(forKey: Keys.isAuthenticated)
        print("🔍 Main App: getIsAuthenticated() = \(isAuthenticated)")
        print("🔍 Main App: UserDefaults keys available: \(userDefaults.dictionaryRepresentation().keys)")
        return isAuthenticated
    }

    // MARK: - Data Management

    func clearAllData() {
        userDefaults.removeObject(forKey: Keys.contributions)
        userDefaults.removeObject(forKey: Keys.lastUpdated)
        userDefaults.removeObject(forKey: Keys.isAuthenticated)
        userDefaults.synchronize()
    }
}
