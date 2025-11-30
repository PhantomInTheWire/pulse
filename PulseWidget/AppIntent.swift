//
//  AppIntent.swift
//  PulseWidget
//
//  Created by Karan Haresh Lokchandani on 12/11/25.
//

import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Pulse Configuration" }
    static var description: IntentDescription { "GitHub contribution heatmap widget." }
}
