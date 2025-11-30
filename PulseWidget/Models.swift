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

// MARK: - Sample Data for Previews

#if DEBUG
extension ContributionResponse {
    static let sample: ContributionResponse = {
        var weeks: [ContributionWeek] = []
        let calendar = Calendar.current
        let today = Date()

        // Generate 53 weeks of data (approx 1 year)
        for weekOffset in (0..<53).reversed() {
            var days: [ContributionDay] = []

            // Calculate start of the week (Sunday)
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekDate))
            else {
                continue
            }

            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: date)

                // Generate random contribution level
                // Bias towards lower levels to look realistic
                let randomValue = Int.random(in: 0...10)
                let level: Int
                let count: Int

                switch randomValue {
                case 0:  // 10% chance of no contributions
                    level = 0
                    count = 0
                case 1...6:  // 60% chance of low
                    level = 1
                    count = Int.random(in: 1...3)
                case 7...9:  // 30% chance of medium
                    level = 2
                    count = Int.random(in: 4...7)
                case 10:  // 10% chance of high/very high
                    level = Int.random(in: 3...4)
                    count = Int.random(in: 8...15)
                default:
                    level = 0
                    count = 0
                }

                days.append(ContributionDay(date: dateString, count: count, level: level))
            }
            weeks.append(ContributionWeek(days: days))
        }

        return ContributionResponse(weeks: weeks)
    }()
}
#endif
