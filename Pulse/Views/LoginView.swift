//
//  LoginView.swift
//  Pulse
//
//  Created by Karan Haresh Lokchandani on 11/30/25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: GitHubAuthService
    
    var body: some View {
        switch authService.authState {
        case .notAuthenticated:
            notAuthenticatedView
        case .awaitingUser:
            awaitingUserView
        case .polling:
            pollingView
        default:
            EmptyView()
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
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(authService.userCode, forType: .string)
                    #elseif os(iOS)
                    UIPasteboard.general.string = authService.userCode
                    #endif
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
            
            Text("Polling for authorization...")
                .font(.headline)
            
            VStack(spacing: 8) {
                Text("Your code:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(authService.userCode)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentColor)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Button(action: {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(authService.userCode, forType: .string)
                    #elseif os(iOS)
                    UIPasteboard.general.string = authService.userCode
                    #endif
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
            
            Text("Waiting for you to complete authorization in GitHub...")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
