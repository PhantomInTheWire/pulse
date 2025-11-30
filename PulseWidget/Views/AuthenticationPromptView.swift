//
//  AuthenticationPromptView.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI

struct AuthenticationPromptView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 30))
                .foregroundColor(.secondary)

            Text("Sign in to GitHub")
                .font(.headline)

            Text("Open Pulse to authenticate.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
