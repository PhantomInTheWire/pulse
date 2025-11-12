//
//  ContributionHeatmapView.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI
import WidgetKit

// MARK: - GitHub Colors

struct GitHubColorPalette {
    static let light: [Color] = [
        Color(hex: "EBEDF0"),  // 0
        Color(hex: "9BE9A8"),  // 1
        Color(hex: "40C463"),  // 2
        Color(hex: "30A14E"),  // 3
        Color(hex: "216E39")   // 4
    ]
    
    static let dark: [Color] = [
        Color(hex: "161B22"),  // 0
        Color(hex: "0E4429"),  // 1
        Color(hex: "006D32"),  // 2
        Color(hex: "26A641"),  // 3
        Color(hex: "39D353")   // 4
    ]
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgba: UInt64 = 0
        scanner.scanHexInt64(&rgba)

        let r = Double((rgba >> 16) & 0xFF) / 255
        let g = Double((rgba >> 8) & 0xFF) / 255
        let b = Double(rgba & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Safe Array Access Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Widgets

struct ContributionHeatmapView: View {
    let contributions: ContributionResponse
    let isStale: Bool
    @Environment(\.colorScheme) private var scheme
    
    init(contributions: ContributionResponse, isStale: Bool = false) {
        self.contributions = contributions
        self.isStale = isStale
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            header
            
            heatmap
            
            GitHubLegend()
            
            if isStale {
                Text("Data may be outdated")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .containerBackground(.thinMaterial, for: .widget)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 8) {
            Image("octocat") // Add monochrome GitHub Octocat to Assets
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)

            Text("GitHub Contributions")
                .font(.caption)
                .fontWeight(.semibold)
            
            Spacer()
            
            if isStale {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Heatmap Layout (GitHub-accurate)
    
    private var heatmap: some View {
        LazyHGrid(
            rows: Array(repeating: GridItem(.fixed(11), spacing: 3), count: 7),
            spacing: 3
        ) {
            ForEach(contributions.weeks.indices, id: \.self) { weekIndex in
                if weekIndex < contributions.weeks.count {
                    let week = contributions.weeks[weekIndex]
                    
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if dayIndex < week.days.count {
                            GitHubContributionCell(level: week.days[dayIndex].level)
                        } else {
                            GitHubContributionCell(level: 0)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 4)
    }
}

// MARK: - Heatmap Cell

struct GitHubContributionCell: View {
    let level: Int
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color(for: level))
            .frame(width: 11, height: 11)
    }
    
    private func color(for level: Int) -> Color {
        let palette = (scheme == .dark)
            ? GitHubColorPalette.dark
            : GitHubColorPalette.light
        
        let safe = min(max(level, 0), 4)
        return palette[safe]
    }
}

// MARK: - Legend

struct GitHubLegend: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = (scheme == .dark)
            ? GitHubColorPalette.dark
            : GitHubColorPalette.light
        
        HStack(spacing: 6) {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 3) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(palette[i])
                        .frame(width: 10, height: 10)
                }
            }

            Text("More")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Loading…")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.thinMaterial, for: .widget)
    }
}

// MARK: - Authentication Prompt View

struct AuthenticationPromptView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
            
            Text("Sign in to GitHub")
                .font(.headline)
            
            Text("Open Pulse to authenticate and enable contribution tracking.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.thinMaterial, for: .widget)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 26))
                .foregroundColor(.orange)

            Text("Unable to Load Data")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.thinMaterial, for: .widget)
    }
}
