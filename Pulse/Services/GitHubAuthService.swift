//
//  GitHubAuthService.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import Foundation
#if canImport(AppKit)
import AppKit
#endif
import Combine

class GitHubAuthService: ObservableObject {
    static let shared = GitHubAuthService()
    
    private var clientID: String {
        Bundle.main.object(forInfoDictionaryKey: "GitHubClientID") as? String ?? "Ov23lihSGOuYdGx4X39N"
    }

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
                Task {
                    await fetchUserInfo(with: token)
                }
            }
        } else {
            isAuthenticated = false
            authState = .notAuthenticated
        }
    }
    
    func startDeviceFlow() {
        authState = .awaitingUser
        errorMessage = nil
        
        Task {
            do {
                let response = try await GitHubAPIClient.shared.startDeviceFlow(clientID: clientID)
                
                await MainActor.run {
                    self.deviceCode = response.device_code
                    self.userCode = response.user_code
                    self.verificationURI = response.verification_uri
                    self.pollingInterval = response.interval
                    self.authState = .awaitingUser
                    

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startPolling()
                    }
                }
            } catch {
                await MainActor.run {
                    self.handleError(error as? AuthError ?? .unknownError(error.localizedDescription))
                }
            }
        }
    }
    
    func openVerificationPage() {
        #if os(macOS)
        if let url = URL(string: verificationURI) {
            NSWorkspace.shared.open(url)
        }
        #endif
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
        Task {
            do {
                let response = try await GitHubAPIClient.shared.pollForToken(clientID: clientID, deviceCode: deviceCode)
                await handleSuccessfulAuth(token: response.access_token)
            } catch let error as AuthError {
                await MainActor.run {
                    switch error {
                    case .unknownError(let msg) where msg == "authorization_pending":
                        self.scheduleNextPoll()
                    case .slowDown:
                        self.pollingInterval += 1
                        self.scheduleNextPoll()
                    default:
                        self.handleError(error)
                    }
                }
            } catch {
                await MainActor.run {
                    self.handleError(.unknownError(error.localizedDescription))
                }
            }
        }
    }
    
    private func scheduleNextPoll() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(pollingInterval), repeats: false) { [weak self] _ in
            self?.pollForToken()
        }
    }
    
    @MainActor
    private func handleSuccessfulAuth(token: String) {
        pollingTimer?.invalidate()
        
        do {
            try KeychainManager.shared.saveToken(token)
            Task {
                await fetchUserInfo(with: token)
            }
        } catch {
            handleError(.unknownError("Failed to save token"))
        }
    }
    
    private func fetchUserInfo(with token: String) async {
        do {
            let user = try await GitHubAPIClient.shared.fetchUserInfo(token: token)
            
            await MainActor.run {
                self.currentUser = user
                do {
                    try KeychainManager.shared.saveUserInfo(user)
                    self.isAuthenticated = true
                    self.authState = .authenticated
                    

                    Task {
                        await ContributionManager.shared.handleAuthenticationChange()
                    }
                } catch {
                    self.handleError(.unknownError("Failed to save user info"))
                }
            }
        } catch {
            await MainActor.run {
                self.handleError(error as? AuthError ?? .unknownError(error.localizedDescription))
            }
        }
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
        

        Task {
            await ContributionManager.shared.handleAuthenticationChange()
        }
    }
    
    private func handleError(_ error: AuthError) {
        pollingTimer?.invalidate()
        errorMessage = error.localizedDescription
        authState = .error
    }
    
    func fetchContributions() async throws -> ContributionResponse {
        guard let token = KeychainManager.shared.retrieveToken() else {
            throw AuthError.unknownError("No authentication token found")
        }
        
        return try await GitHubAPIClient.shared.fetchContributions(token: token)
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
}
