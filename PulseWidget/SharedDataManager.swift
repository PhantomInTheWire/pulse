//
//  SharedDataManager.swift
//  PulseWidget
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
        NSLog("🔍 Widget: Attempting to create shared UserDefaults with suite: \(appGroupID)")
        
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            NSLog("✅ Widget: Successfully created shared UserDefaults for app group: \(appGroupID)")
            
            // Test write/read to verify it actually works
            sharedDefaults.set("widget_test", forKey: "widget_shared_test")
            sharedDefaults.synchronize() // Force sync
            
            if sharedDefaults.string(forKey: "widget_shared_test") == "widget_test" {
                NSLog("✅ Widget: Shared UserDefaults read/write test passed")
                sharedDefaults.removeObject(forKey: "widget_shared_test")
                sharedDefaults.synchronize()
                self.userDefaults = sharedDefaults
            } else {
                NSLog("❌ Widget: Shared UserDefaults read/write test failed - falling back to UserDefaults.standard")
                self.userDefaults = UserDefaults.standard
            }
        } else {
            NSLog("❌ Widget: Failed to create shared UserDefaults for app group: \(appGroupID)")
            NSLog("⚠️ Widget: Falling back to UserDefaults.standard - data sharing will not work!")
            self.userDefaults = UserDefaults.standard
        }
        
        // Log which UserDefaults we're actually using
        if self.userDefaults == UserDefaults.standard {
            NSLog("⚠️ Widget: Using UserDefaults.standard - SHARED DATA WILL NOT WORK!")
        } else {
            NSLog("✅ Widget: Using shared UserDefaults for data access")
        }
    }
    
    // MARK: - Contribution Data
    
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
        return userDefaults.object(forKey: Keys.lastUpdated) as? Date
    }
    
    func isDataFresh(maxAge: TimeInterval = 4 * 60 * 60) -> Bool { // 4 hours default
        guard let lastUpdated = getLastUpdatedDate() else {
            return false
        }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdated)
        return timeSinceUpdate < maxAge
    }
    
    // MARK: - Authentication State
    
    func getIsAuthenticated() -> Bool {
        NSLog("🔍 Widget: Checking authentication state...")
        NSLog("🔍 Widget: UserDefaults instance type: \(type(of: userDefaults))")
        NSLog("🔍 Widget: Is UserDefaults.standard? \(userDefaults == UserDefaults.standard)")
        
        // Check if key exists
        let hasKey = userDefaults.object(forKey: Keys.isAuthenticated) != nil
        NSLog("🔍 Widget: Has '\(Keys.isAuthenticated)' key? \(hasKey)")
        
        let isAuthenticated = userDefaults.bool(forKey: Keys.isAuthenticated)
        NSLog("🔍 Widget: getIsAuthenticated() = \(isAuthenticated)")
        
        // Only log keys if we're using standard (to avoid spamming with shared data)
        if userDefaults == UserDefaults.standard {
            NSLog("🔍 Widget: UserDefaults keys (first 10): \(Array(userDefaults.dictionaryRepresentation().keys.prefix(10)))")
        }
        
        return isAuthenticated
    }
}
