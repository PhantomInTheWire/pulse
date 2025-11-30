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

struct ContributionDay: Codable {
    let date: String
    let count: Int
    let level: Int
}

struct ContributionWeek: Codable {
    let days: [ContributionDay]
}

struct ContributionResponse: Codable {
    let weeks: [ContributionWeek]
}

enum ContributionLevel: Int, CaseIterable, Codable {
    case zero = 0
    case low = 1
    case medium = 2
    case high = 3
    case veryHigh = 4

    var opacity: Double {
        switch self {
        case .zero: return 0.0
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .veryHigh: return 1.0
        }
    }
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

// MARK: - Sample Data for Previews

#if DEBUG
extension ContributionResponse {
    static let sample: ContributionResponse = {
        var weeks: [ContributionWeek] = []
        let calendar = Calendar.current
        let today = Date()

        for weekOffset in (0..<53).reversed() {
            var days: [ContributionDay] = []

            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekDate))
            else {
                continue
            }

            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: date)

                let randomValue = Int.random(in: 0...10)
                let level: Int
                let count: Int

                switch randomValue {
                case 0:
                    level = 0
                    count = 0
                case 1...6:
                    level = 1
                    count = Int.random(in: 1...3)
                case 7...9:
                    level = 2
                    count = Int.random(in: 4...7)
                case 10:
                    level = Int.random(in: 3...4)
                    count = Int.random(in: 8...15)
                default:
                    level = 0
                    count = 0
                }

                days.append(ContributionDay(date: dateString, count: count, level: level))
            }
            weeks.append(ContributionWeek(days: days))
        }

        return ContributionResponse(weeks: weeks)
    }()
}
#endif
