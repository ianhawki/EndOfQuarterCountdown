# End of Quarter Countdown

A lightweight macOS menu bar app that counts down to the end of your current financial quarter.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift 5](https://img.shields.io/badge/Swift-5-orange) ![Xcode 15+](https://img.shields.io/badge/Xcode-15%2B-blue)

## Features

- Lives in the menu bar — no Dock icon
- Displays the current quarter and days remaining (e.g. `FY26 Q2 · 45d`)
- Click to expand a popup showing days, current week, and weeks remaining
- Tracks five quarters — Q1–Q4 of the current FY plus Q1 of the next FY
- Automatically counts down to whichever quarter you are currently in
- FY label updates automatically when the quarter rolls over
- Syncs quarter dates from a configurable URL
- Dates and last-sync time are saved and remembered between launches
- Recalculates instantly when the system timezone changes
- Hardened Runtime enabled

## New FY Warning

When fewer than 70 days remain on the final stored quarter (next FY Q1):

- The **menu bar icon turns orange** and the calendar icon changes to a warning triangle
- An **orange banner** appears in the popup with two actions:
  - **Sync Now** — fetches updated dates from the configured URL
  - **Edit Dates** — opens the date editor to update manually

The warning clears automatically once dates are updated and the countdown moves past Q5.

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

The app defaults to `https://hawkinsmultimedia.com.au/endofquarter.html`. Any URL can be used as long as the page lists five quarters in this format:
```
FY26Q1 : 25/10/2025
FY26Q2 : 25/01/2026
FY26Q3 : 25/04/2026
FY26Q4 : 25/07/2026
FY27Q1 : 25/10/2026
```
Each line includes the FY label and quarter number. The fifth entry is the next FY's Q1 and acts as a transition buffer. The URL is saved to UserDefaults and remembered between launches.

## Project Structure

```
EndOfQuarterCountdown/
├── EndOfQuarterApp.swift     # App entry point, menu bar label and warning state
├── QuarterModel.swift        # Quarter logic, 5-quarter tracking, web sync, UserDefaults
└── QuarterView.swift         # Popup UI, date editor, sync status, new FY warning banner
```

## Contributing

Pull requests are welcome. For larger changes please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
