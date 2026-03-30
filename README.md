# End of Quarter Countdown

A lightweight macOS menu bar app that counts down to the end of your current financial quarter.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift 5](https://img.shields.io/badge/Swift-5-orange) ![Xcode 15+](https://img.shields.io/badge/Xcode-15%2B-blue)

## Features

- Lives in the menu bar — no Dock icon
- Displays the current quarter and days remaining (e.g. `Q2 · 45d`)
- Click to expand a popup showing days, hours, and minutes
- Set your own Q1, Q2, Q3 and Q4 end dates manually or sync from a URL
- Automatically counts down to whichever quarter you are currently in
- Dates and last-sync time are saved and remembered between launches
- Hardened Runtime enabled

## Requirements

- macOS 13.0 or later
- Xcode 15 or later

## Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/ianhawki/EndOfQuarterCountdown.git
   ```
2. Open `EndOfQuarterCountdown.xcodeproj` in Xcode
3. In the **Signing & Capabilities** tab, set the Team to your Apple ID
4. Press **Cmd+R** to build and run

## Setting Your Quarter Dates

### Manually
1. Click the menu bar icon
2. Click the **sliders icon** (top right of the popup)
3. Pick your own end date for each quarter using the date pickers
4. Dates save automatically

### Sync from the web
1. Click the menu bar icon and open the editor with the **sliders icon**
2. Edit the **Sync URL** field and press **Save** to point it at any page you like
3. Click the **iCloud sync icon** (header, next to the sliders icon) to fetch dates
4. The editor panel shows the last synced time and any errors

The app defaults to `https://hawkinsmultimedia.com.au/endofquarter.html`. Any URL can be used as long as the page contains dates in this format:
```
Q1 : 25/10/2025
Q2 : 24/01/2026
Q3 : 25/04/2026
Q4 : 25/07/2026
```
The URL is saved to UserDefaults and remembered between launches.

## Project Structure

```
EndOfQuarterCountdown/
├── EndOfQuarterApp.swift     # App entry point and menu bar setup
├── QuarterModel.swift        # Quarter logic, web sync, UserDefaults persistence
└── QuarterView.swift         # Popup UI, date editor, and sync status
```

## Contributing

Pull requests are welcome. For larger changes please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
