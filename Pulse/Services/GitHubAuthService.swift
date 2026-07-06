//
//  GitHubAuthService.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import Combine
import Foundation
import WidgetKit

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

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
    private var deviceCodeExpiresAt: Date?
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

            // token gone (revoked externally / keychain reset) — clear the shared
            // auth flag so the widget stops rendering stale data. Use
            // SharedDataManager/WidgetCenter directly: this runs during init,
            // and touching ContributionManager.shared here would deadlock the
            // singleton initializers.
            SharedDataManager.shared.setAuthenticated(false)
            WidgetCenter.shared.reloadAllTimelines()
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
                    self.deviceCodeExpiresAt = Date().addingTimeInterval(TimeInterval(response.expires_in))
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
        guard let url = URL(string: verificationURI) else { return }
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif canImport(UIKit)
        UIApplication.shared.open(url)
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
                handleSuccessfulAuth(token: response.access_token)
            } catch let error as AuthError {
                await MainActor.run {
                    switch error {
                    case .authorizationPending:
                        self.scheduleNextPoll()
                    case .slowDown:
                        // RFC 8628: on slow_down, increase the polling interval by 5 seconds
                        self.pollingInterval += 5
                        self.scheduleNextPoll()
                    case .networkError, .invalidResponse:
                        // transient server/transport trouble — keep polling until the code expires
                        self.scheduleNextPoll()
                    default:
                        self.handleError(error)
                    }
                }
            } catch {
                await MainActor.run {
                    // transient transport error (e.g. connection dropped while the app
                    // was backgrounded for Safari) — keep polling, don't abort the flow
                    self.scheduleNextPoll()
                }
            }
        }
    }

    private func scheduleNextPoll() {
        if let expiry = deviceCodeExpiresAt, Date() >= expiry {
            handleError(.authorizationExpired)
            return
        }
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

    private func fetchUserInfo(with token: String, isRetry: Bool = false) async {
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
            let authError = error as? AuthError ?? .unknownError(error.localizedDescription)

            if case .tokenRevoked = authError {
                // token is genuinely dead — clean up the session
                await MainActor.run {
                    self.logout()
                }
                return
            }

            if !isRetry {
                // likely a transient network failure (e.g. right after the token
                // grant) — retry once before discarding a perfectly good session
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await fetchUserInfo(with: token, isRetry: true)
                return
            }

            await MainActor.run {
                self.handleError(authError)
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
