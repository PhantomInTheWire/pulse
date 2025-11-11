//
//  GitHubAuthService.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import Foundation
import AppKit
import Combine

class GitHubAuthService: ObservableObject {
    static let shared = GitHubAuthService()
    
    private var clientID: String {
        Bundle.main.object(forInfoDictionaryKey: "GitHubClientID") as? String ?? "Ov23lihSGOuYdGx4X39N"
    }

    private let baseURL = "https://github.com"
    
    @Published var isAuthenticated = false
    @Published var currentUser: GitHubUser?
    @Published var authState: AuthState = .notAuthenticated
    @Published var userCode: String = ""
    @Published var verificationURI: String = ""
    @Published var errorMessage: String?

    private var pollingTimer: Timer?
    private var deviceCode: String = ""
    private var pollingInterval: Int = 5
    private var cancellables = Set<AnyCancellable>()
    
    enum AuthState {
        case notAuthenticated
        case awaitingUser
        case polling
        case authenticated
        case error
    }
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        if let token = KeychainManager.shared.retrieveToken() {
            if let user = KeychainManager.shared.retrieveUserInfo() {
                isAuthenticated = true
                currentUser = user
                authState = .authenticated
            } else {
                fetchUserInfo(with: token)
            }
        } else {
            isAuthenticated = false
            authState = .notAuthenticated
        }
    }
    
    func startDeviceFlow() {
        authState = .awaitingUser
        errorMessage = nil
        
        var request = URLRequest(url: URL(string: "\(baseURL)/login/device/code")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = "client_id=\(clientID)&scope=repo,workflow".data(using: .utf8)
        
        print("GitHub Device Flow Request: \(request.url?.absoluteString ?? "No URL")")
        print("Request Body: client_id=\(clientID)&scope=repo,workflow")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.handleError(.networkError(error.localizedDescription))
                    return
                }
                
                guard let data = data else {
                    self.handleError(.invalidResponse)
                    return
                }
                
                // Debug: Print raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("GitHub Device Flow Response: \(responseString)")
                }
                
                // Try JSON parsing first
                do {
                    let authResponse = try JSONDecoder().decode(DeviceAuthResponse.self, from: data)
                    self.deviceCode = authResponse.device_code
                    self.userCode = authResponse.user_code
                    self.verificationURI = authResponse.verification_uri
                    self.pollingInterval = authResponse.interval
                    
                    self.authState = .awaitingUser
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startPolling()
                    }
                } catch {
                    // Fallback to URL-encoded parsing
                    guard let responseString = String(data: data, encoding: .utf8) else {
                        self.handleError(.invalidResponse)
                        return
                    }
                    
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
                    
                    guard let deviceCode = authData["device_code"],
                          let userCode = authData["user_code"],
                          let verificationURIString = authData["verification_uri"],
                          let intervalString = authData["interval"],
                          let interval = Int(intervalString) else {
                        print("Failed to parse device flow response: \(authData)")
                        self.handleError(.invalidResponse)
                        return
                    }
                    
                    self.deviceCode = deviceCode
                    self.userCode = userCode
                    self.verificationURI = verificationURIString.removingPercentEncoding ?? verificationURIString
                    self.pollingInterval = interval
                    
                    self.authState = .awaitingUser
                }
            }
        }.resume()
    }
    
    func openVerificationPage() {
        NSWorkspace.shared.open(URL(string: verificationURI)!)
    }
    
    func startPollingManually() {
        authState = .polling
        pollForToken()
    }
    
    private func startPolling() {
        authState = .polling
        pollForToken()
    }
    
    private func pollForToken() {
        var request = URLRequest(url: URL(string: "\(baseURL)/login/oauth/access_token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = "client_id=\(clientID)&device_code=\(deviceCode)&grant_type=urn:ietf:params:oauth:grant-type:device_code".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.handleError(.networkError(error.localizedDescription))
                    return
                }
                
                guard let data = data else {
                    self.handleError(.invalidResponse)
                    return
                }
                
                // Debug: Print polling response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("GitHub Polling Response: \(responseString)")
                }
                
                // First check if response contains an error (regardless of status code)
                if let responseString = String(data: data, encoding: .utf8),
                   let responseData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let error = responseData["error"] as? String {
                    
                    print("GitHub OAuth Error: \(error)")
                    
                    if error == "authorization_pending" {
                        self.scheduleNextPoll()
                        return
                    } else if error == "slow_down" {
                        self.pollingInterval += 1
                        self.scheduleNextPoll()
                        return
                    } else if error == "expired_token" {
                        self.handleError(.authorizationExpired)
                        return
                    } else if error == "access_denied" {
                        self.handleError(.accessDenied)
                        return
                    } else {
                        self.handleError(.unknownError(error))
                        return
                    }
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        // Try JSON parsing first
                        do {
                            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                            self.handleSuccessfulAuth(token: tokenResponse.access_token)
                        } catch {
                            // Fallback to URL-encoded parsing
                            guard let responseString = String(data: data, encoding: .utf8) else {
                                self.handleError(.invalidResponse)
                                return
                            }
                            
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
                            
                            guard let accessToken = tokenData["access_token"] else {
                                print("Failed to parse token response: \(tokenData)")
                                self.handleError(.invalidResponse)
                                return
                            }
                            
                            self.handleSuccessfulAuth(token: accessToken)
                        }
                    } else if httpResponse.statusCode == 400 {
                        if let responseString = String(data: data, encoding: .utf8) {
                            if responseString.contains("authorization_pending") {
                                self.scheduleNextPoll()
                            } else if responseString.contains("slow_down") {
                                self.pollingInterval += 1
                                self.scheduleNextPoll()
                            } else if responseString.contains("expired_token") {
                                self.handleError(.authorizationExpired)
                            } else if responseString.contains("access_denied") {
                                self.handleError(.accessDenied)
                            } else {
                                self.handleError(.unknownError(responseString))
                            }
                        } else {
                            self.handleError(.invalidResponse)
                        }
                    } else {
                        self.handleError(.unknownError("HTTP \(httpResponse.statusCode)"))
                    }
                }
            }
        }.resume()
    }
    
    private func scheduleNextPoll() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(pollingInterval), repeats: false) { [weak self] _ in
            self?.pollForToken()
        }
    }
    
    private func handleSuccessfulAuth(token: String) {
        print("🎉 Authentication successful! Token received: \(token.prefix(10))...")
        pollingTimer?.invalidate()
        
        do {
            try KeychainManager.shared.saveToken(token)
            print("✅ Token saved to Keychain")
            fetchUserInfo(with: token)
        } catch {
            print("❌ Failed to save token: \(error)")
            handleError(.unknownError("Failed to save token"))
        }
    }
    
    private func fetchUserInfo(with token: String) {
        print("👤 Fetching user info...")
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        print("User info request: \(request.url?.absoluteString ?? "No URL")")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ User info fetch error: \(error)")
                    self.handleError(.networkError(error.localizedDescription))
                    return
                }
                
                guard let data = data else {
                    print("❌ No user data received")
                    self.handleError(.invalidResponse)
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("👤 User info response: \(responseString)")
                }
                
                do {
                    let user = try JSONDecoder().decode(GitHubUser.self, from: data)
                    print("✅ User info decoded: \(user.login)")
                    self.currentUser = user
                    
                    do {
                        try KeychainManager.shared.saveUserInfo(user)
                        print("✅ User info saved to Keychain")
                        self.isAuthenticated = true
                        self.authState = .authenticated
                        print("🎉 Authentication complete!")
                    } catch {
                        print("❌ Failed to save user info: \(error)")
                        self.handleError(.unknownError("Failed to save user info"))
                    }
                } catch {
                    print("❌ Failed to decode user info: \(error)")
                    self.handleError(.invalidResponse)
                }
            }
        }.resume()
    }
    
    func logout() {
        pollingTimer?.invalidate()
        
        do {
            try KeychainManager.shared.deleteToken()
            try KeychainManager.shared.deleteUserInfo()
        } catch {
            print("Failed to delete credentials: \(error)")
        }
        
        isAuthenticated = false
        currentUser = nil
        authState = .notAuthenticated
        userCode = ""
        verificationURI = ""
        errorMessage = nil
    }
    
    private func handleError(_ error: AuthError) {
        pollingTimer?.invalidate()
        errorMessage = error.localizedDescription
        authState = .error
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
}
