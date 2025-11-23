# Pulse

A GitHub Contribution Heatmap Widget for iOS and macOS.

---

![Demo from Pulse](https://github.com/user-attachments/assets/1eb16506-036b-4fa3-bfd0-e1cd7734b156)

---

## Description

Pulse is a native SwiftUI application that displays your GitHub contribution heatmap directly on your device's home screen or desktop via a widget. It securely authenticates with GitHub using the device authorization flow and periodically fetches your contribution data to keep the widget up-to-date.

## Features

- **Secure Authentication**: Uses GitHub's device flow for secure, token-based authentication
- **Real-time Updates**: Automatically fetches contribution data every 2 hours
- **Cross-Platform**: Supports both iOS and macOS
- **Privacy**: Stores data locally and securely using Keychain
- **Widget Integration**: Displays contribution heatmap in a medium-sized widget

## Requirements

- Xcode 15.0 or later
- iOS 17.0+ or macOS 14.0+
- GitHub account

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/pulse.git
   cd pulse
   ```

2. Open the project in Xcode:
   ```bash
   open Pulse.xcodeproj
   ```

3. Build and run the app on your device or simulator.

## Setup
1. Launch the Pulse app
2. Click "Connect to GitHub" to start authentication
3. Follow the on-screen instructions to authorize the app on GitHub
4. Once authenticated, add the Pulse widget to your home screen (iOS) or desktop (macOS)

## Widget Setup

### iOS
1. Long press on your home screen
2. Tap the "+" icon in the top-left corner
3. Search for "Pulse" and select it
4. Choose the medium widget size
5. Add the widget to your home screen

### macOS
1. Open Notification Center
2. Scroll to the bottom and click "Edit Widgets"
3. Search for "Pulse" and add it to your desktop

## Usage

- The widget will automatically update every 2 hours
- Use the main app to manually refresh data or disconnect your GitHub account
- The heatmap shows your GitHub contributions over the past year

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License
