//
//  ContentView.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject private var authService = GitHubAuthService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
            switch authService.authState {
            case .notAuthenticated:
                notAuthenticatedView
            case .awaitingUser:
                awaitingUserView
            case .polling:
                pollingView
            case .authenticated:
                authenticatedView
            case .error:
                errorView
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("Pulse")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("GitHub Contribution Heatmap Widget")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var notAuthenticatedView: some View {
        VStack(spacing: 16) {
            Text("Connect your GitHub account to view your contribution heatmap in the widget.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                authService.startDeviceFlow()
            }) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Connect to GitHub")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var awaitingUserView: some View {
        VStack(spacing: 16) {
            Text("Step 1: Open GitHub in your browser")
                .font(.headline)
            
            Button(action: {
                authService.openVerificationPage()
            }) {
                HStack {
                    Image(systemName: "safari")
                    Text("Open GitHub")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            Text("Step 2: Enter this code on GitHub")
                .font(.headline)
            
            VStack(spacing: 8) {
                Text(authService.userCode)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentColor)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(authService.userCode, forType: .string)
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Code")
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Text("After authorizing on GitHub, click Continue below:")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                authService.startPollingManually()
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle")
                    Text("Continue - I've Authorized on GitHub")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var pollingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Waiting for authorization...")
                .font(.headline)
            
            Text("Please complete the authorization in your browser.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var authenticatedView: some View {
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
                
                Text("Your GitHub account is connected and ready to use with the Pulse widget.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
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
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Authentication Failed")
                .font(.headline)
            
            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                authService.startDeviceFlow()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    ContentView()
}
