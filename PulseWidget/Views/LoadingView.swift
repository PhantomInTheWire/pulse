//
//  LoadingView.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading…")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
