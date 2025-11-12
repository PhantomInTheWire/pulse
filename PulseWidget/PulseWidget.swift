//
//  PulseWidget.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import WidgetKit
import SwiftUI

enum WidgetState {
    case loading
    case authenticated(ContributionResponse)
    case notAuthenticated
    case error(String)
    case staleData(ContributionResponse)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), state: .loading)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = fetchEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        let entry = fetchEntry(date: currentDate)
        
        // Determine next update time based on data freshness
        let nextUpdate: Date
        switch entry.state {
        case .authenticated, .staleData:
            // If we have data, check again in 2 hours
            nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        case .notAuthenticated, .error, .loading:
            // If no data or error, check again in 30 minutes
            nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        }
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry(date: Date) -> SimpleEntry {
        let sharedData = SharedDataManager.shared
        
        // Check if user is authenticated
        guard sharedData.getIsAuthenticated() else {
            return SimpleEntry(date: date, state: .notAuthenticated)
        }
        
        // Get contributions from shared storage
        guard let contributions = sharedData.retrieveContributions() else {
            return SimpleEntry(date: date, state: .error("No contribution data available"))
        }
        
        // Check if data is fresh
        if sharedData.isDataFresh() {
            return SimpleEntry(date: date, state: .authenticated(contributions))
        } else {
            return SimpleEntry(date: date, state: .staleData(contributions))
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let state: WidgetState
}

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
            ErrorView(message: message)
        }
    }
}

struct PulseWidget: Widget {
    let kind: String = "PulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PulseWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("GitHub Pulse")
        .description("View your GitHub contribution heatmap")
        .supportedFamilies([.systemMedium])
    }
}
