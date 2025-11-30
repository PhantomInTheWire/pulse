//
//  ErrorView.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 26))

            Text("Unable to load data")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
