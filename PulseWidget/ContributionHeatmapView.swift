//
//  ContributionHeatmapView.swift
//  PulseWidget
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

    @Environment(\.colorScheme) private var scheme

    init(contributions: ContributionResponse, isStale: Bool = false) {
        self.contributions = contributions
        self.isStale = isStale
    }
    
    var body: some View {
        VStack() {
            heatmap
            if isStale {
                Text("Data may be outdated")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: Heatmap
    
    private var heatmap: some View {
        let weeks = contributions.last(weeks: 22)
        
        return LazyHGrid(
            rows: Array(repeating: GridItem(.fixed(16), spacing: 3), count: 7),
            spacing: 2
        ) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                let week = weeks[weekIndex]
                
                ForEach(0..<7, id: \.self) { dayIndex in
                    if let day = week.days[safe: dayIndex] {
                        GitHubContributionCell(level: day.level)
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
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 11, height: 11)
    }
    
    private var color: Color {
        let palette = DynamicGitHubPalette.palette(accent: Color.accentColor, scheme: scheme)
        return palette[min(max(level, 0), 4)]
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
