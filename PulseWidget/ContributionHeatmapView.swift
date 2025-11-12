//
//  ContributionHeatmapView.swift
//  PulseWidget
//
//  Redesigned GitHub + macOS-native version
//

import SwiftUI
import WidgetKit

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
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Dynamic macOS Accent-Based Palette

struct DynamicGitHubPalette {
    static func palette(for accent: Color, scheme: ColorScheme) -> [Color] {
        
        // Level 0: neutral background tone
        let zero = scheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.06)

        // Accent-driven multiplier palette
        return [
            zero,
            accent.opacity(0.30),
            accent.opacity(0.50),
            accent.opacity(0.70),
            accent.opacity(1.0)
        ]
    }
}

// MARK: - Main Heatmap View

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
        .containerBackground(for: .widget) {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                
                // Subtle macOS widget shadow
                LinearGradient(
                    colors: [
                        Color.black.opacity(scheme == .dark ? 0.20 : 0.07),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 8) {
            Image("octocat") // Add monochrome Octocat to Assets
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
                    .font(.caption)
            }
        }
    }
    
    // MARK: - GitHub-Accurate Grid Layout
    
    private var heatmap: some View {
        LazyHGrid(
            rows: Array(repeating: GridItem(.fixed(9), spacing: 2), count: 7),
            spacing: 2
        ) {
            ForEach(contributions.weeks.indices, id: \.self) { weekIndex in
                
                if weekIndex < contributions.weeks.count {
                    let week = contributions.weeks[weekIndex]
                    
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
        .padding(.vertical, 4)
    }
}

// MARK: - Heatmap Cell (Accent-Adaptive)

struct GitHubContributionCell: View {
    let level: Int
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color(for: level))
            .frame(width: 9, height: 9)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(scheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
            )
    }
    
    private func color(for level: Int) -> Color {
        let palette = DynamicGitHubPalette.palette(for: .accentColor, scheme: scheme)
        return palette[min(max(level, 0), 4)]
    }
}

// MARK: - GitHub Legend (Accent Adaptive)

struct GitHubLegend: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = DynamicGitHubPalette.palette(for: .accentColor, scheme: scheme)
        
        HStack(spacing: 6) {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 3) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(palette[i])
                        .frame(width: 9, height: 9)
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
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

// MARK: - Authentication Prompt View

struct AuthenticationPromptView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            
            Text("Sign in to GitHub")
                .font(.headline)
            
            Text("Open Pulse to authenticate and view your contributions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.ultraThinMaterial, for: .widget)
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
                .padding(.horizontal, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}
