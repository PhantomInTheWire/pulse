//
//  GitHubAuthModels.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import Foundation

struct DeviceAuthResponse: Codable {
    let device_code: String
    let user_code: String
    let verification_uri: String
    let interval: Int
    let expires_in: Int
}

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let scope: String
}

struct GitHubUser: Codable {
    let login: String
    let id: Int
    let name: String?
    let email: String?
    let avatar_url: String
}

enum AuthError: Error, LocalizedError {
    case networkError(String)
    case invalidResponse
    case authorizationExpired
    case accessDenied
    case slowDown
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .authorizationExpired:
            return "Authorization code expired"
        case .accessDenied:
            return "Access denied by user"
        case .slowDown:
            return "Please wait before trying again"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}