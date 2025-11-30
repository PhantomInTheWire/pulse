//
//  PulseWidgetEntryView.swift
//  PulseWidgetExtension
//
//  Created by Karan Haresh Lokchandani on 11/30/25.
//

import SwiftUI
import WidgetKit

struct PulseWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        switch entry.state {
        case .loading:
            // Placeholder for loading state if needed, or just show empty/shimmer
            Text("Loading...")
        case .authenticated(let contributions):
            ContributionHeatmapView(contributions: contributions)
        case .staleData(let contributions):
            ContributionHeatmapView(contributions: contributions, isStale: true)
        case .notAuthenticated:
            // You might want a dedicated view for this
            VStack {
                Text("Please log in")
                Text("Open App")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        case .error(let message):
            VStack {
                Image(systemName: "exclamationmark.triangle")
                Text(message)
                    .font(.caption)
            }
        }
    }
}
