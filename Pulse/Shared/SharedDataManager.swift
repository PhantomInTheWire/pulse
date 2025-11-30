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

        NSLog("SharedDataManager: Attempting to create shared UserDefaults with suite: \(appGroupID)")

        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            NSLog("SharedDataManager: Successfully created shared UserDefaults for app group: \(appGroupID)")

            sharedDefaults.set("test_value", forKey: "shared_test")
            sharedDefaults.synchronize()

            if sharedDefaults.string(forKey: "shared_test") == "test_value" {
                NSLog("SharedDataManager: Shared UserDefaults read/write test passed")
                sharedDefaults.removeObject(forKey: "shared_test")
                sharedDefaults.synchronize()
                self.userDefaults = sharedDefaults
            } else {
                NSLog("SharedDataManager: Shared UserDefaults read/write test failed - falling back to UserDefaults.standard")
                self.userDefaults = UserDefaults.standard
            }
        } else {
            NSLog("SharedDataManager: Failed to create shared UserDefaults for app group: \(appGroupID)")
            NSLog("SharedDataManager: Falling back to UserDefaults.standard - data sharing will not work!")
            self.userDefaults = UserDefaults.standard
        }

        if self.userDefaults == UserDefaults.standard {
            NSLog("SharedDataManager: Using UserDefaults.standard - SHARED DATA WILL NOT WORK!")
        } else {
            NSLog("SharedDataManager: Using shared UserDefaults for data access")
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
            print("Saved \(contributions.weeks.count) weeks of contributions to UserDefaults")
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
        NSLog("SharedDataManager: Checking authentication state...")
        NSLog("SharedDataManager: UserDefaults instance type: \(type(of: userDefaults))")
        NSLog("SharedDataManager: Is UserDefaults.standard? \(userDefaults == UserDefaults.standard)")

        let hasKey = userDefaults.object(forKey: Keys.isAuthenticated) != nil
        NSLog("SharedDataManager: Has '\(Keys.isAuthenticated)' key? \(hasKey)")

        let isAuthenticated = userDefaults.bool(forKey: Keys.isAuthenticated)
        NSLog("SharedDataManager: getIsAuthenticated() = \(isAuthenticated)")

        if userDefaults == UserDefaults.standard {
            NSLog("SharedDataManager: UserDefaults keys (first 10): \(Array(userDefaults.dictionaryRepresentation().keys.prefix(10)))")
        }

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
