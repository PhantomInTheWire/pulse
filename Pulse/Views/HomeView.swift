//
//  HomeView.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 11/30/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var authService: GitHubAuthService
    @ObservedObject private var contributionManager = ContributionManager.shared

    var body: some View {
        VStack(spacing: 16) {
            if let user = authService.currentUser {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: user.avatar_url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.login)
                            .font(.headline)

                        if let name = user.name {
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                VStack(spacing: 8) {
                    Text("Your GitHub account is connected and ready to use with the Pulse widget.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    if let lastUpdated = contributionManager.lastUpdated {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("Last updated: \(lastUpdated, style: .relative) ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let lastError = contributionManager.lastError {
                        Text(lastError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await contributionManager.fetchContributions()
                        }
                    }) {
                        HStack {
                            if contributionManager.isFetching {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Refresh")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(contributionManager.isFetching)

                    Button(action: {
                        authService.logout()
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.minus")
                            Text("Disconnect")
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
