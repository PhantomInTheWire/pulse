//
//  ContributionHeatmapView.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI
import WidgetKit

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Last N Weeks Extension

extension ContributionResponse {
    func last(weeks count: Int) -> [ContributionWeek] {
        Array(weeks.suffix(count))
    }
}

// MARK: - Dynamic Accent-Based Palette

struct DynamicGitHubPalette {
    static func palette(accent: Color, scheme: ColorScheme) -> [Color] {
        let zero = scheme == .dark
            ? Color.white.opacity(0.07)
            : Color.black.opacity(0.08)

        return [
            zero,
            accent.opacity(0.30),
            accent.opacity(0.50),
            accent.opacity(0.70),
            accent.opacity(1.0)
        ]
    }
}

// MARK: - Heatmap View

struct ContributionHeatmapView: View {
    let contributions: ContributionResponse
    let isStale: Bool
    
    // Number of weeks to display
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

// MARK: - Cell

struct GitHubContributionCell: View {
    let level: Int
    var count: Int = 0
    @Environment(\.colorScheme) private var scheme
    
    // Map contribution count to color level
    private func countToLevel(_ count: Int) -> Int {
        switch count {
        case 0:
            return 0
        case 1...3:
            return 1
        case 4...6:
            return 2
        case 7...9:
            return 3
        default: // 10+
            return 4
        }
    }
    
    var body: some View {
        if count > 10 {
            Text("🔥")
                .font(.system(size: 10))
                .frame(width: 15, height: 15)
        } else {
            let palette = DynamicGitHubPalette.palette(accent: .accentColor, scheme: scheme)
            let colorLevel = countToLevel(count)
            RoundedRectangle(cornerRadius: 4)
                .fill(palette[colorLevel])
                .frame(width: 15, height: 15)
        }
    }
}

// MARK: - Loading

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

// MARK: - Authentication

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

// MARK: - Error

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
