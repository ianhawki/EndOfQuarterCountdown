import Foundation

@MainActor
class QuarterModel: ObservableObject {
    @Published var q1End: Date { didSet { saveComponents(of: q1End, key: "q1c"); update() } }
    @Published var q2End: Date { didSet { saveComponents(of: q2End, key: "q2c"); update() } }
    @Published var q3End: Date { didSet { saveComponents(of: q3End, key: "q3c"); update() } }
    @Published var q4End: Date { didSet { saveComponents(of: q4End, key: "q4c"); update() } }

    @Published var daysRemaining: Int = 0
    @Published var hoursRemaining: Int = 0
    @Published var minutesRemaining: Int = 0
    @Published var currentQuarter: Int = 1
    @Published var currentQuarterEnd: Date = Date()

    @Published var isFetching = false
    @Published var fetchError: String? = nil
    @Published var lastFetched: Date? = nil
    @Published var financialYear: String = ""
    @Published var feedURLString: String {
        didSet { UserDefaults.standard.set(feedURLString, forKey: "feedURL") }
    }

    private static let defaultFeedURL = "https://hawkinsmultimedia.com.au/endofquarter.html"

    // Suppresses saves while rebuilding after a timezone change
    private var isRebuilding = false
    private var timer: Timer?

    init() {
        let defaults = UserDefaults.standard

        q1End = Self.loadDate(key: "q1c", fallbackMonth: 3,  fallbackDay: 31)
        q2End = Self.loadDate(key: "q2c", fallbackMonth: 6,  fallbackDay: 30)
        q3End = Self.loadDate(key: "q3c", fallbackMonth: 9,  fallbackDay: 30)
        q4End = Self.loadDate(key: "q4c", fallbackMonth: 12, fallbackDay: 31)
        feedURLString  = defaults.string(forKey: "feedURL")        ?? Self.defaultFeedURL
        financialYear  = defaults.string(forKey: "financialYear") ?? ""

        if let saved = defaults.object(forKey: "lastFetched") as? Date {
            lastFetched = saved
        }

        update()

        // Recalculate every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }

        // Rebuild dates when the system timezone changes
        NotificationCenter.default.addObserver(
            forName: Notification.Name("NSSystemTimeZoneDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.rebuildDatesFromComponents() }
        }
    }

    // MARK: - Timezone rebuild

    /// Reload all four dates from stored components using the new current timezone.
    private func rebuildDatesFromComponents() {
        isRebuilding = true
        q1End = Self.loadDate(key: "q1c", fallbackMonth: 3,  fallbackDay: 31)
        q2End = Self.loadDate(key: "q2c", fallbackMonth: 6,  fallbackDay: 30)
        q3End = Self.loadDate(key: "q3c", fallbackMonth: 9,  fallbackDay: 30)
        q4End = Self.loadDate(key: "q4c", fallbackMonth: 12, fallbackDay: 31)
        isRebuilding = false
        update()
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

            // Parse financial year (e.g. "FY26")
            let fyRegex = try NSRegularExpression(pattern: "(FY\\d+)")
            if let fyMatch = fyRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let fyRange = Range(fyMatch.range(at: 1), in: html) {
                financialYear = String(html[fyRange])
                UserDefaults.standard.set(financialYear, forKey: "financialYear")
            }

            // Parse quarter dates — extract raw day/month/year, no DateFormatter to avoid timezone offset
            let qRegex = try NSRegularExpression(pattern: "Q(\\d)\\s*:\\s*(\\d{2})/(\\d{2})/(\\d{4})")
            let matches = qRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))

            guard !matches.isEmpty else {
                fetchError = "No quarter dates found on page"
                isFetching = false
                return
            }

            for match in matches {
                guard let qRange  = Range(match.range(at: 1), in: html),
                      let ddRange = Range(match.range(at: 2), in: html),
                      let mmRange = Range(match.range(at: 3), in: html),
                      let yyyyRange = Range(match.range(at: 4), in: html),
                      let quarter = Int(html[qRange]),
                      let day     = Int(html[ddRange]),
                      let month   = Int(html[mmRange]),
                      let year    = Int(html[yyyyRange]) else { continue }

                let date = Self.makeDate(year: year, month: month, day: day)
                switch quarter {
                case 1: q1End = date
                case 2: q2End = date
                case 3: q3End = date
                case 4: q4End = date
                default: break
                }
            }

            lastFetched = Date()
            UserDefaults.standard.set(lastFetched, forKey: "lastFetched")

        } catch {
            fetchError = error.localizedDescription
        }

        isFetching = false
    }

    // MARK: - Countdown

    func update() {
        let now = Date()
        let quarters = [(1, q1End), (2, q2End), (3, q3End), (4, q4End)]

        if let next = quarters.first(where: { $0.1 > now }) {
            currentQuarter    = next.0
            currentQuarterEnd = next.1
        } else {
            currentQuarter    = 4
            currentQuarterEnd = q4End
        }

        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: currentQuarterEnd)
        daysRemaining    = max(0, components.day    ?? 0)
        hoursRemaining   = max(0, components.hour   ?? 0)
        minutesRemaining = max(0, components.minute ?? 0)
    }

    // MARK: - Storage (components, not Date objects)

    private func saveComponents(of date: Date, key: String) {
        guard !isRebuilding else { return }
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let y = comps.year, let m = comps.month, let d = comps.day else { return }
        UserDefaults.standard.set(["y": y, "m": m, "d": d], forKey: key)
    }

    private static func loadDate(key: String, fallbackMonth: Int, fallbackDay: Int) -> Date {
        if let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Int],
           let y = dict["y"], let m = dict["m"], let d = dict["d"] {
            return makeDate(year: y, month: m, day: d)
        }
        let year = Calendar.current.component(.year, from: Date())
        return makeDate(year: year, month: fallbackMonth, day: fallbackDay)
    }

    /// Builds a Date for end-of-day in the current local timezone — no timezone offsets applied.
    static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        c.hour = 23; c.minute = 59; c.second = 59
        return Calendar.current.date(from: c) ?? Date()
    }

    deinit { timer?.invalidate() }
}
