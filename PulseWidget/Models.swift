//
//  Models.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import Foundation

struct ContributionDay: Codable {
    let date: String
    let count: Int
    let level: Int
}

struct ContributionWeek: Codable {
    let days: [ContributionDay]
}

struct ContributionResponse: Codable {
    let weeks: [ContributionWeek]
}

enum ContributionLevel: Int, CaseIterable, Codable {
    case zero = 0
    case low = 1
    case medium = 2
    case high = 3
    case veryHigh = 4
    
    var opacity: Double {
        switch self {
        case .zero: return 0.0
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .veryHigh: return 1.0
        }
    }
}