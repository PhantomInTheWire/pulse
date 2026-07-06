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
    private let spacing: CGFloat = 3

    @Environment(\.colorScheme) private var scheme

    init(contributions: ContributionResponse, isStale: Bool = false) {
        self.contributions = contributions
        self.isStale = isStale
    }

    var body: some View {
        GeometryReader { geo in
            // Cell size fills the height (7 rows); week count fills the width
            let cell = (geo.size.height - 6 * spacing) / 7
            let weekCount = max(1, Int((geo.size.width + spacing) / (cell + spacing)))
            let weeks = contributions.last(weeks: weekCount)

            LazyHGrid(
                rows: Array(repeating: GridItem(.fixed(cell), spacing: spacing), count: 7),
                spacing: spacing
            ) {
                ForEach(weeks.indices, id: \.self) { weekIndex in
                    let week = weeks[weekIndex]

                    ForEach(0..<7, id: \.self) { dayIndex in
                        if let day = week.days[safe: dayIndex] {
                            GitHubContributionCell(level: day.level, count: day.count, size: cell)
                        } else {
                            // Future days in the current week stay blank, like GitHub
                            Color.clear.frame(width: cell, height: cell)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(10)  // content margins are disabled; just enough inset to clear the container's rounded corners
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
}
