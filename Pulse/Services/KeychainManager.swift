//
//  KeychainManager.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import Foundation

class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    private let service = "com.pulse.github"

    func saveToken(_ token: String) throws {
        try saveData(Data(token.utf8), account: "github_token")
    }

    func retrieveToken() -> String? {
        guard let data = retrieveData(account: "github_token") else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func deleteToken() throws {
        try deleteData(account: "github_token")
    }

    func saveUserInfo(_ user: GitHubUser) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)

        try saveData(data, account: "github_user")
    }

    func retrieveUserInfo() -> GitHubUser? {
        guard let data = retrieveData(account: "github_user") else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(GitHubUser.self, from: data)
    }

    func deleteUserInfo() throws {
        try deleteData(account: "github_user")
    }

    private func saveData(_ data: Data, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    private func retrieveData(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return data
    }

    private func deleteData(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed
        }
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed
    case deleteFailed
    case retrieveFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data to keychain"
        case .deleteFailed:
            return "Failed to delete data from keychain"
        case .retrieveFailed:
            return "Failed to retrieve data from keychain"
        }
    }
}
