//
//  ContributionHeatmapView.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI
import WidgetKit

struct ContributionHeatmapView: View {
    let contributions: ContributionResponse
    let isStale: Bool
    @Environment(\.colorScheme) var colorScheme
    
    init(contributions: ContributionResponse, isStale: Bool = false) {
        self.contributions = contributions
        self.isStale = isStale
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("GitHub Contributions")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if isStale {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(contributions.weeks.indices, id: \.self) { weekIndex in
                    let week = contributions.weeks[weekIndex]
                    ForEach(week.days.indices, id: \.self) { dayIndex in
                        let day = week.days[dayIndex]
                        ContributionCell(day: day)
                            .id("\(weekIndex)-\(dayIndex)")
                    }
                }
            }
            
            HStack {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(ContributionLevel.allCases, id: \.self) { level in
                        Rectangle()
                            .fill(accentColor.opacity(level.opacity))
                            .frame(width: 8, height: 8)
                            .cornerRadius(1)
                    }
                }
                Spacer()
                Text("More")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if isStale {
                Text("Data may be outdated")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private var accentColor: Color {
        return Color.blue
    }
}

struct ContributionCell: View {
    let day: ContributionDay
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: 10, height: 10)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }
    
    private var cellColor: Color {
        let level = ContributionLevel(rawValue: day.level) ?? .zero
        let accentColor: Color = Color.blue
        
        if level == .zero {
            return Color.primary.opacity(0.05)
        } else {
            return accentColor.opacity(level.opacity)
        }
    }
}

struct AuthenticationPromptView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("GitHub Authentication Required")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Open the Pulse app to authenticate with GitHub and view your contribution heatmap.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Pulse") {
                if let url = URL(string: "pulse://auth") {
                    // Widget can't open URLs directly, this is handled by the app intent
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Loading contributions...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            Text("Unable to load contributions")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}