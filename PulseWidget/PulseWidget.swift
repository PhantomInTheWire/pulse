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
            nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        case .notAuthenticated, .error, .loading:
            nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        }
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry(date: Date) -> SimpleEntry {
        let sharedData = SharedDataManager.shared
        
        guard sharedData.getIsAuthenticated() else {
            return SimpleEntry(date: date, state: .notAuthenticated)
        }
        
        guard let contributions = sharedData.retrieveContributions() else {
            return SimpleEntry(date: date, state: .error("No contribution data available"))
        }
        
        return SimpleEntry(
            date: date,
            state: sharedData.isDataFresh() ? .authenticated(contributions) : .staleData(contributions)
        )
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
                .containerBackground(for: .widget) {
                    ContainerRelativeShape()
                        .fill(.background)
                }
        }
        .configurationDisplayName("GitHub Pulse")
        .description("View your GitHub contribution heatmap")
        .supportedFamilies([.systemMedium])
    }
}


struct PulseWidget_Previews: PreviewProvider {
    static var previews: some View {
        PulseWidgetEntryView(entry: SimpleEntry(date: .now, state: .authenticated(ContributionResponse.sample)))
            .containerBackground(for: .widget) {
                ContainerRelativeShape()
                    .fill(.background)
            }
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
