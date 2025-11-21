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

// MARK: - Theme

struct Theme {
    static func color(for level: Int, scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // Dark mode: use distinct shades for better visibility
            switch level {
            case 0:
                return Color.white.opacity(0.08)
            case 1:
                return Color(red: 0.0, green: 0.3, blue: 0.15)
            case 2:
                return Color(red: 0.0, green: 0.5, blue: 0.25)
            case 3:
                return Color(red: 0.0, green: 0.7, blue: 0.35)
            case 4:
                return Color(red: 0.0, green: 0.9, blue: 0.45)
            default:
                return Color.white.opacity(0.08)
            }
        } else {
            // Light mode: use opacity on green
            let baseColor = Color.green
            switch level {
            case 0:
                return Color.black.opacity(0.05)
            case 1:
                return baseColor.opacity(0.3)
            case 2:
                return baseColor.opacity(0.5)
            case 3:
                return baseColor.opacity(0.7)
            case 4:
                return baseColor.opacity(0.9)
            default:
                return Color.black.opacity(0.05)
            }
        }
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
    
    var body: some View {
        if count > 10 {
            Text("🔥")
                .font(.system(size: 10))
                .frame(width: 15, height: 15)
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.color(for: level, scheme: scheme))
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
