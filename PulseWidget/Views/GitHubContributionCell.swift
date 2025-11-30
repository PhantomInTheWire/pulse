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
    @Environment(\.colorScheme) private var scheme

    private func countToLevel(_ count: Int) -> Int {
        switch count {
        case 0: return 0
        case 1...3: return 1
        case 4...6: return 2
        case 7...9: return 3
        default: return 4
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
