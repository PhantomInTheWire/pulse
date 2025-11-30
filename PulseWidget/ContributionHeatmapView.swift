//
//  ContributionHeatmapView.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI
import WidgetKit



// MARK: - Heatmap View

struct ContributionHeatmapView: View {
    let contributions: ContributionResponse
    let isStale: Bool
    private let weekCount = 18
    
    @Environment(\.colorScheme) private var scheme

    init(contributions: ContributionResponse, isStale: Bool = false) {
        self.contributions = contributions
        self.isStale = isStale
    }
    
    var body: some View {
        heatmap
            .padding()
            .overlay(
                isStale ? staleOverlay : nil,
                alignment: .bottomTrailing
            )
    }
    
    // MARK: Components
    
    private var staleOverlay: some View {
        Text("Outdated")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.orange)
            .padding(4)
            .background(Color.black.opacity(0.6))
            .cornerRadius(4)
            .padding(4)
    }
    
    private var heatmap: some View {
        let weeks = contributions.last(weeks: weekCount)
        
        return LazyHGrid(
            rows: Array(repeating: GridItem(.fixed(15), spacing: 3), count: 7),
            spacing: 3
        ) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                let week = weeks[weekIndex]
                
                ForEach(0..<7, id: \.self) { dayIndex in
                    if let day = week.days[safe: dayIndex] {
                        GitHubContributionCell(level: day.level, count: day.count)
                    } else {
                        GitHubContributionCell(level: 0)
                    }
                }
            }
        }
    }
}


