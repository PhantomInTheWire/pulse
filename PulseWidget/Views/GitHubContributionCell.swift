//
//  GitHubContributionCell.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI

struct GitHubContributionCell: View {
    let level: Int
    var count: Int = 0
    var size: CGFloat = 15
    /// Days at or above this count render as 🔥. Tuned to ~90th percentile of
    /// the owner's recent activity so only genuine spike days burn.
    static let fireThreshold = 50
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if count >= Self.fireThreshold {
            // README design: hot days are a bare flame, no cell background
            Text("🔥")
                .font(.system(size: size * 0.8))
                .minimumScaleFactor(0.5)
                .frame(width: size, height: size)
        } else {
            // Color.accentColor doesn't resolve to the asset catalog inside a
            // widget extension (SpringBoard hosts it) — look the color up by name
            let palette = DynamicGitHubPalette.palette(accent: Color("AccentColor"), scheme: scheme)
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(palette[min(max(level, 0), palette.count - 1)])
                .frame(width: size, height: size)
        }
    }
}
