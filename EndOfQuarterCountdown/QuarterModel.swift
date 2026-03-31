import Foundation
import ServiceManagement

@MainActor
class QuarterModel: ObservableObject {

    // Five quarter end dates — Q1–Q4 of current FY + Q1 of next FY
    @Published var q1End: Date { didSet { saveComponents(of: q1End, key: "q1c"); update() } }
    @Published var q2End: Date { didSet { saveComponents(of: q2End, key: "q2c"); update() } }
    @Published var q3End: Date { didSet { saveComponents(of: q3End, key: "q3c"); update() } }
    @Published var q4End: Date { didSet { saveComponents(of: q4End, key: "q4c"); update() } }
    @Published var q5End: Date { didSet { saveComponents(of: q5End, key: "q5c"); update() } }

    // FY label per quarter (e.g. "FY26") — populated from web sync
    @Published var q1FY: String = ""
    @Published var q2FY: String = ""
    @Published var q3FY: String = ""
    @Published var q4FY: String = ""
    @Published var q5FY: String = ""

    @Published var daysRemaining: Int = 0
    @Published var weeksRemaining: Int = 0
    @Published var currentWeekNumber: Int = 1

    /// 1–5 internally; use currentDisplayQuarter for UI (Q5 shows as Q1 of next FY)
    @Published var currentQuarter: Int = 1
    @Published var currentQuarterEnd: Date = Date()

    /// The FY label for whichever quarter we're currently counting down to
    @Published var financialYear: String = ""

    @Published var launchAtLogin: Bool = false

    @Published var isFetching = false
    @Published var fetchError: String? = nil
    @Published var lastFetched: Date? = nil
    @Published var feedURLString: String {
        didSet { UserDefaults.standard.set(feedURLString, forKey: "feedURL") }
    }

    /// Quarter number to show in the UI — Q5 is presented as Q1 of the next FY
    var currentDisplayQuarter: Int { currentQuarter == 5 ? 1 : currentQuarter }

    /// True when counting down to the final stored quarter (next FY Q1) with fewer than 70 days left
    var shouldWarnNextFY: Bool { currentQuarter == 5 && daysRemaining < 70 }

    private static let defaultFeedURL = "https://hawkinsmultimedia.com.au/endofquarter.html"
    private var isSyncingFromComponents = false
    private var timer: Timer?

    init() {
        let d = UserDefaults.standard
        let year = Calendar.current.component(.year, from: Date())

        q1End = Self.loadDate(key: "q1c", fallbackMonth: 3,  fallbackDay: 31, fallbackYear: year)
        q2End = Self.loadDate(key: "q2c", fallbackMonth: 6,  fallbackDay: 30, fallbackYear: year)
        q3End = Self.loadDate(key: "q3c", fallbackMonth: 9,  fallbackDay: 30, fallbackYear: year)
        q4End = Self.loadDate(key: "q4c", fallbackMonth: 12, fallbackDay: 31, fallbackYear: year)
        q5End = Self.loadDate(key: "q5c", fallbackMonth: 3,  fallbackDay: 31, fallbackYear: year + 1)

        q1FY = d.string(forKey: "q1FY") ?? ""
        q2FY = d.string(forKey: "q2FY") ?? ""
        q3FY = d.string(forKey: "q3FY") ?? ""
        q4FY = d.string(forKey: "q4FY") ?? ""
        q5FY = d.string(forKey: "q5FY") ?? ""

        feedURLString = d.string(forKey: "feedURL") ?? Self.defaultFeedURL

        if let saved = d.object(forKey: "lastFetched") as? Date { lastFetched = saved }

        launchAtLogin = SMAppService.mainApp.status == .enabled

        update()

        // Check every 10 minutes as a safety net
        timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name("NSSystemTimeZoneDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }
    }

    // MARK: - Countdown

    func update() {
        guard !isSyncingFromComponents else { return }

        // Rebuild dates from stored components in the current timezone so
        // a timezone change never shifts the calendar day.
        isSyncingFromComponents = true
        let year = Calendar.current.component(.year, from: Date())
        q1End = Self.loadDate(key: "q1c", fallbackMonth: 3,  fallbackDay: 31, fallbackYear: year)
        q2End = Self.loadDate(key: "q2c", fallbackMonth: 6,  fallbackDay: 30, fallbackYear: year)
        q3End = Self.loadDate(key: "q3c", fallbackMonth: 9,  fallbackDay: 30, fallbackYear: year)
        q4End = Self.loadDate(key: "q4c", fallbackMonth: 12, fallbackDay: 31, fallbackYear: year)
        q5End = Self.loadDate(key: "q5c", fallbackMonth: 3,  fallbackDay: 31, fallbackYear: year + 1)
        isSyncingFromComponents = false

        let now = Date()
        let cal = Calendar.current
        let quarters = [(1, q1End), (2, q2End), (3, q3End), (4, q4End), (5, q5End)]

        if let next = quarters.first(where: { $0.1 > now }) {
            currentQuarter    = next.0
            currentQuarterEnd = next.1
        } else {
            currentQuarter    = 5
            currentQuarterEnd = q5End
        }

        // Update the FY badge to match whichever quarter we're in
        financialYear = fyLabel(for: currentQuarter)

        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: now),
            to: cal.startOfDay(for: currentQuarterEnd)
        ).day ?? 0

        daysRemaining     = max(0, days)
        weeksRemaining    = max(0, daysRemaining / 7)
        currentWeekNumber = weekNumber(quarterStart: currentQuarterStart, today: now)
    }

    func fyLabel(for quarter: Int) -> String {
        switch quarter {
        case 1: return q1FY
        case 2: return q2FY
        case 3: return q3FY
        case 4: return q4FY
        case 5: return q5FY
        default: return ""
        }
    }

    /// The first day of the current quarter (day after the previous quarter ended).
    var currentQuarterStart: Date {
        let cal = Calendar.current
        func dayAfter(_ d: Date) -> Date {
            cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: d))!
        }
        switch currentQuarter {
        case 2: return dayAfter(q1End)
        case 3: return dayAfter(q2End)
        case 4: return dayAfter(q3End)
        case 5: return dayAfter(q4End)
        default: // Q1 — approximate from Q4 end one year prior
            let prevQ4End = cal.date(byAdding: .year, value: -1, to: q4End) ?? q4End
            return dayAfter(prevQ4End)
        }
    }

    private func weekNumber(quarterStart: Date, today: Date) -> Int {
        let cal = Calendar.current
        let qDay     = cal.startOfDay(for: quarterStart)
        let todayDay = cal.startOfDay(for: today)

        let qWeekday    = cal.component(.weekday, from: qDay)
        let daysToWeek1 = (cal.firstWeekday - qWeekday + 7) % 7

        guard let week1Start = cal.date(byAdding: .day, value: daysToWeek1, to: qDay) else { return 1 }
        if todayDay < week1Start { return 0 }

        let elapsed = cal.dateComponents([.day], from: week1Start, to: todayDay).day ?? 0
        return elapsed / 7 + 1
    }

    // MARK: - Web Fetch

    func fetchDates() async {
        isFetching = true
        fetchError = nil

        guard let feedURL = URL(string: feedURLString),
              feedURL.scheme == "https" || feedURL.scheme == "http" else {
            fetchError = "Invalid URL"
            isFetching = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            guard let html = String(data: data, encoding: .utf8) else {
                fetchError = "Could not read page content"
                isFetching = false
                return
            }

            // Format: FY26Q1 : 25/10/2025
            let pattern = "(FY\\d+)Q(\\d)\\s*:\\s*(\\d{2})/(\\d{2})/(\\d{4})"
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

            guard !matches.isEmpty else {
                fetchError = "No quarter dates found on page"
                isFetching = false
                return
            }

            // Collect all entries then assign in order
            var entries: [(fy: String, quarter: Int, date: Date)] = []

            for match in matches {
                guard let fyRange   = Range(match.range(at: 1), in: html),
                      let qRange    = Range(match.range(at: 2), in: html),
                      let ddRange   = Range(match.range(at: 3), in: html),
                      let mmRange   = Range(match.range(at: 4), in: html),
                      let yyyyRange = Range(match.range(at: 5), in: html),
                      let quarter   = Int(html[qRange]),
                      let day       = Int(html[ddRange]),
                      let month     = Int(html[mmRange]),
                      let year      = Int(html[yyyyRange]) else { continue }

                let fy   = String(html[fyRange])
                let date = Self.makeDate(year: year, month: month, day: day)
                entries.append((fy: fy, quarter: quarter, date: date))
            }

            // Assign the first four entries to Q1–Q4, the fifth to Q5 (next FY Q1)
            if entries.count > 0 { q1End = entries[0].date; q1FY = entries[0].fy; UserDefaults.standard.set(q1FY, forKey: "q1FY") }
            if entries.count > 1 { q2End = entries[1].date; q2FY = entries[1].fy; UserDefaults.standard.set(q2FY, forKey: "q2FY") }
            if entries.count > 2 { q3End = entries[2].date; q3FY = entries[2].fy; UserDefaults.standard.set(q3FY, forKey: "q3FY") }
            if entries.count > 3 { q4End = entries[3].date; q4FY = entries[3].fy; UserDefaults.standard.set(q4FY, forKey: "q4FY") }
            if entries.count > 4 { q5End = entries[4].date; q5FY = entries[4].fy; UserDefaults.standard.set(q5FY, forKey: "q5FY") }

            lastFetched = Date()
            UserDefaults.standard.set(lastFetched, forKey: "lastFetched")

        } catch {
            fetchError = error.localizedDescription
        }

        isFetching = false
    }

    // MARK: - Storage

    private func saveComponents(of date: Date, key: String) {
        guard !isSyncingFromComponents else { return }
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let y = comps.year, let m = comps.month, let d = comps.day else { return }
        UserDefaults.standard.set(["y": y, "m": m, "d": d], forKey: key)
    }

    private static func loadDate(key: String, fallbackMonth: Int, fallbackDay: Int, fallbackYear: Int) -> Date {
        if let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Int],
           let y = dict["y"], let m = dict["m"], let d = dict["d"] {
            return makeDate(year: y, month: m, day: d)
        }
        return makeDate(year: fallbackYear, month: fallbackMonth, day: fallbackDay)
    }

    static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        c.hour = 23; c.minute = 59; c.second = 59
        return Calendar.current.date(from: c) ?? Date()
    }

    // MARK: - Launch at Login

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at login error: \(error.localizedDescription)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    deinit { timer?.invalidate() }
}
