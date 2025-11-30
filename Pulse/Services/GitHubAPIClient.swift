//
//  GitHubAPIClient.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 11/30/25.
//

import Foundation

class GitHubAPIClient {
    static let shared = GitHubAPIClient()
    private let baseURL = "https://github.com"
    private let apiBaseURL = "https://api.github.com"

    private init() {}

    func startDeviceFlow(clientID: String) async throws -> DeviceAuthResponse {
        let url = URL(string: "\(baseURL)/login/device/code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = "client_id=\(clientID)&scope=repo,workflow".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(DeviceAuthResponse.self, from: data)
        } catch {

            if let responseString = String(data: data, encoding: .utf8) {
                let components = responseString.components(separatedBy: "&")
                var authData: [String: String] = [:]

                for component in components {
                    let keyValue = component.components(separatedBy: "=")
                    if keyValue.count == 2 {
                        let key = keyValue[0]
                        let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                        authData[key] = value
                    }
                }

                if let deviceCode = authData["device_code"],
                    let userCode = authData["user_code"],
                    let verificationURI = authData["verification_uri"],
                    let intervalString = authData["interval"],
                    let interval = Int(intervalString),
                    let expiresInString = authData["expires_in"],
                    let expiresIn = Int(expiresInString)
                {

                    return DeviceAuthResponse(
                        device_code: deviceCode,
                        user_code: userCode,
                        verification_uri: verificationURI,
                        interval: interval,
                        expires_in: expiresIn
                    )
                }
            }
            throw AuthError.invalidResponse
        }
    }

    func pollForToken(clientID: String, deviceCode: String) async throws -> TokenResponse {
        let url = URL(string: "\(baseURL)/login/oauth/access_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = "client_id=\(clientID)&device_code=\(deviceCode)&grant_type=urn:ietf:params:oauth:grant-type:device_code".data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = responseData["error"] as? String
        {

            switch error {
            case "authorization_pending": throw AuthError.unknownError("authorization_pending")
            case "slow_down": throw AuthError.slowDown
            case "expired_token": throw AuthError.authorizationExpired
            case "access_denied": throw AuthError.accessDenied
            default: throw AuthError.unknownError(error)
            }
        }

        do {
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {

            if let responseString = String(data: data, encoding: .utf8) {
                let components = responseString.components(separatedBy: "&")
                var tokenData: [String: String] = [:]

                for component in components {
                    let keyValue = component.components(separatedBy: "=")
                    if keyValue.count == 2 {
                        let key = keyValue[0]
                        let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                        tokenData[key] = value
                    }
                }

                if let accessToken = tokenData["access_token"],
                    let tokenType = tokenData["token_type"],
                    let scope = tokenData["scope"]
                {
                    return TokenResponse(access_token: accessToken, token_type: tokenType, scope: scope)
                }
            }
            throw AuthError.invalidResponse
        }
    }

    func fetchUserInfo(token: String) async throws -> GitHubUser {
        let url = URL(string: "\(apiBaseURL)/user")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.invalidResponse
        }

        return try JSONDecoder().decode(GitHubUser.self, from: data)
    }

    func fetchContributions(token: String) async throws -> ContributionResponse {
        let query = """
            query {
              viewer {
                contributionsCollection {
                  contributionCalendar {
                    weeks {
                      contributionDays {
                        date
                        contributionCount
                        contributionLevel
                      }
                    }
                  }
                }
              }
            }
            """

        let url = URL(string: "\(apiBaseURL)/graphql")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("No HTTP response received")
        }

        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthError.networkError("GitHub API returned status \(httpResponse.statusCode): \(responseString)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.invalidResponse
        }

        if let errors = json["errors"] as? [[String: Any]] {
            let errorMessages = errors.compactMap { $0["message"] as? String }
            throw AuthError.unknownError("GraphQL errors: \(errorMessages.joined(separator: ", "))")
        }

        guard let dataDict = json["data"] as? [String: Any],
            let viewer = dataDict["viewer"] as? [String: Any],
            let contributionsCollection = viewer["contributionsCollection"] as? [String: Any],
            let contributionCalendar = contributionsCollection["contributionCalendar"] as? [String: Any],
            let weeksData = contributionCalendar["weeks"] as? [[String: Any]]
        else {
            throw AuthError.invalidResponse
        }

        var weeks: [ContributionWeek] = []

        for weekData in weeksData {
            guard let daysData = weekData["contributionDays"] as? [[String: Any]] else { continue }

            var days: [ContributionDay] = []
            for dayData in daysData {
                guard let date = dayData["date"] as? String,
                    let count = dayData["contributionCount"] as? Int,
                    let levelString = dayData["contributionLevel"] as? String
                else { continue }

                let level: Int
                switch levelString {
                case "NONE": level = 0
                case "FIRST_QUARTILE": level = 1
                case "SECOND_QUARTILE": level = 2
                case "THIRD_QUARTILE": level = 3
                case "FOURTH_QUARTILE": level = 4
                default: level = 0
                }

                days.append(ContributionDay(date: date, count: count, level: level))
            }

            weeks.append(ContributionWeek(days: days))
        }

        return ContributionResponse(weeks: weeks)
    }
}
