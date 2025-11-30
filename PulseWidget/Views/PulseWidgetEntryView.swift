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
            LoadingView()
        case .authenticated(let contributions):
            ContributionHeatmapView(contributions: contributions)
        case .staleData(let contributions):
            ContributionHeatmapView(contributions: contributions, isStale: true)
        case .notAuthenticated:
            AuthenticationPromptView()
        case .error(let message):
            ErrorView(error: message)
        }
    }
}
