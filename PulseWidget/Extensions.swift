//
//  Extensions.swift
//  PulseWidget
//
//  Created by Antigravity on 11/29/25.
//

import SwiftUI

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension ContributionResponse {
    func last(weeks count: Int) -> [ContributionWeek] {
        Array(weeks.suffix(count))
    }
}
