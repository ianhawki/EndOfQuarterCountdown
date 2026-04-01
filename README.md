# End of Quarter Countdown

A lightweight macOS menu bar app that counts down to the end of your current financial quarter — with a matching desktop widget for macOS Sonoma.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Widget macOS 14+](https://img.shields.io/badge/Widget-macOS%2014%2B-purple) ![Swift 5](https://img.shields.io/badge/Swift-5-orange) ![Version](https://img.shields.io/badge/version-2.0.0-green)

---

## Features

### Menu Bar App
- Lives in the menu bar — no Dock icon
- Displays current FY, quarter and days remaining (e.g. `FY26 Q3 · 24d`)
- Click to open a dark-themed popup with full countdown detail
- Tracks **five quarters** — Q1–Q4 of the current FY plus Q1 of the next FY
- Rolls over automatically to the next quarter as each one ends
- Recalculates instantly when the system timezone changes
- **Launch at Login** support via SMAppService

### Popup UI (v2.0 Dark Theme)
- **Large Arial Black countdown number** with blue gradient, with DAYS label at 20% size alongside
- Weeks remaining and full end-of-quarter date displayed below the number
- **Quarter progress bar** — shows current day within the quarter (e.g. Day 66 of 90) with percentage
- **Info cards** — Week Number in current quarter, and FY End Date with days remaining
- FY badge and Q label in the header
- Cloud sync button and pencil edit button in the header

### New FY Warning
When fewer than 70 days remain on the final stored quarter (next FY Q1):
- The **menu bar icon turns orange** with a warning triangle
- An **amber warning banner** appears in the popup with two actions:
  - **Sync Now** — fetches updated dates from the configured URL
  - **Edit Dates** — opens the date editor to update manually

### Web Sync
- Syncs quarter end dates from any configurable URL
- Parses dates in `FY26Q1 : 25/10/2025` format (dd/mm/yyyy)
- Stores last-synced time and shows it in the editor panel
- Defaults to `https://hawkinsmultimedia.com.au/endofquarter.html`

### Desktop Widget (macOS 14+ Sonoma)
- **Small** — FY badge, large countdown number, quarter label, weeks remaining
- **Medium** — countdown + progress bar (Day X of Y) + weeks left + FY end date
- Matches the app's dark theme with blue gradient number
- Refreshes daily at midnight via WidgetKit
- Shares data with the main app via App Groups

---

## Requirements

| Component | Minimum |
|---|---|
| Menu bar app | macOS 13.0 (Ventura) |
| Desktop widget | macOS 14.0 (Sonoma) |
| Xcode | 15 or later |

---

## Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/ianhawki/EndOfQuarterCountdown.git
   ```
2. Open `EndOfQuarterCountdown.xcodeproj` in Xcode
3. In **Signing & Capabilities**, set the Team to your Apple Developer account
4. Press `⌘R` to build and run

---

## Setting Your Quarter Dates

### Sync from the web (recommended)
1. Click the menu bar icon to open the popup
2. Click the **cloud sync icon** (top right) to fetch dates from the default URL
3. To use your own URL, click the **pencil icon** → edit the Sync URL field → click the cloud sync icon

The page must list quarters in this format:
```
FY26Q1 : 25/10/2025
FY26Q2 : 25/01/2026
FY26Q3 : 25/04/2026
FY26Q4 : 25/07/2026
FY27Q1 : 25/10/2026
```
Each line includes the FY label, quarter number, and end date (dd/mm/yyyy).
The fifth entry is the next FY's Q1 — it acts as a rollover buffer and triggers the 70-day warning.

### Manually
1. Click the menu bar icon
2. Click the **pencil icon** (top right of the popup)
3. Pick your end date for each of the five quarters using the date pickers
4. Dates save automatically

---

## Widget Setup (macOS 14+)

The widget reads dates from a shared App Group container. To enable data sharing:

1. In Xcode, select the **EndOfQuarterCountdown** target → **Signing & Capabilities** → **+** → **App Groups**
   - Add: `group.com.example.endofquartercountdown`
2. Repeat for the **EndOfQuarterWidget** target
3. Build and run
4. Right-click the desktop → **Edit Widgets** → find **Quarter Countdown** → add Small or Medium

---

## Project Structure

```
EndOfQuarterCountdown/
├── EndOfQuarterApp.swift          # App entry, menu bar label, warning state
├── QuarterModel.swift             # Quarter logic, 5-quarter tracking, web sync,
│                                  # App Group UserDefaults, launch at login
└── QuarterView.swift              # Dark-theme popup UI — countdown, progress bar,
                                   # info cards, date editor, FY warning banner

EndOfQuarterWidget/
├── EndOfQuarterWidget.swift       # WidgetKit provider, small + medium views
├── EndOfQuarterWidgetBundle.swift # Widget entry point
└── EndOfQuarterWidget.entitlements
```

---

## Author

Built by [Ian Hawkins](mailto:ian@hawkinsmultimedia.net)

## License

[MIT](LICENSE)
