# End of Quarter Countdown

A lightweight macOS menu bar app that counts down to the end of your current financial quarter.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift 5](https://img.shields.io/badge/Swift-5-orange) ![Xcode 15+](https://img.shields.io/badge/Xcode-15%2B-blue)

## Features

- Lives in the menu bar — no Dock icon
- Displays the current quarter and days remaining (e.g. `Q2 · 45d`)
- Click to expand a popup showing days, hours, and minutes
- Set your own Q1, Q2, Q3 and Q4 end dates
- Automatically counts down to whichever quarter you are currently in
- Dates are saved and remembered between launches

## Requirements

- macOS 13.0 or later
- Xcode 15 or later

## Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/YOUR_USERNAME/EndOfQuarterCountdown.git
   ```
2. Open `EndOfQuarterCountdown.xcodeproj` in Xcode
3. In the **Signing & Capabilities** tab, set the Team to your Apple ID
4. Press **Cmd+R** to build and run

## Setting Your Quarter Dates

The app defaults to standard calendar quarters (Mar 31, Jun 30, Sep 30, Dec 31). To change them:

1. Click the menu bar icon
2. Click the **sliders icon** (top right of the popup)
3. Pick your own end date for each quarter
4. Dates save automatically

## Project Structure

```
EndOfQuarterCountdown/
├── EndOfQuarterApp.swift     # App entry point and menu bar setup
├── QuarterModel.swift        # Quarter logic, date calculation, UserDefaults persistence
└── QuarterView.swift         # Popup UI and date editor
```

## Contributing

Pull requests are welcome. For larger changes please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
