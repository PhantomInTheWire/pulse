//
//  DynamicGitHubPalette.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import SwiftUI

struct DynamicGitHubPalette {
    static func palette(accent: Color, scheme: ColorScheme) -> [Color] {
        let zero = scheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.08)
        return [
            zero,
            accent.opacity(0.30),
            accent.opacity(0.50),
            accent.opacity(0.70),
            accent.opacity(1.0),
        ]
    }
}
