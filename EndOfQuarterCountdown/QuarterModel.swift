import Foundation

@MainActor
class QuarterModel: ObservableObject {
    @Published var q1End: Date { didSet { save(); update() } }
    @Published var q2End: Date { didSet { save(); update() } }
    @Published var q3End: Date { didSet { save(); update() } }
    @Published var q4End: Date { didSet { save(); update() } }

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
    private var timer: Timer?

    init() {
        let defaults = UserDefaults.standard
        let year = Calendar.current.component(.year, from: Date())

        q1End = (defaults.object(forKey: "q1End") as? Date) ?? Self.date(month: 3,  day: 31, year: year)
        q2End = (defaults.object(forKey: "q2End") as? Date) ?? Self.date(month: 6,  day: 30, year: year)
        q3End = (defaults.object(forKey: "q3End") as? Date) ?? Self.date(month: 9,  day: 30, year: year)
        q4End = (defaults.object(forKey: "q4End") as? Date) ?? Self.date(month: 12, day: 31, year: year)
        feedURLString  = defaults.string(forKey: "feedURL")        ?? Self.defaultFeedURL
        financialYear  = defaults.string(forKey: "financialYear") ?? ""

        if let saved = defaults.object(forKey: "lastFetched") as? Date {
            lastFetched = saved
        }

        update()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }
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

            // Parse quarter dates (e.g. "Q1 : 25/10/2025")
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            formatter.locale = Locale(identifier: "en_AU")

            let qRegex = try NSRegularExpression(pattern: "Q(\\d)\\s*:\\s*(\\d{2}/\\d{2}/\\d{4})")
            let matches = qRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))

            guard !matches.isEmpty else {
                fetchError = "No quarter dates found on page"
                isFetching = false
                return
            }

            for match in matches {
                guard let qRange = Range(match.range(at: 1), in: html),
                      let dRange = Range(match.range(at: 2), in: html),
                      let quarter = Int(html[qRange]),
                      let date = formatter.date(from: String(html[dRange])) else { continue }

                let endOfDay = endOfDay(date)
                switch quarter {
                case 1: q1End = endOfDay
                case 2: q2End = endOfDay
                case 3: q3End = endOfDay
                case 4: q4End = endOfDay
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

    // MARK: - Helpers

    private func endOfDay(_ date: Date) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        c.hour = 23; c.minute = 59; c.second = 59
        return Calendar.current.date(from: c) ?? date
    }

    static func date(month: Int, day: Int, year: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        c.hour = 23; c.minute = 59; c.second = 59
        return Calendar.current.date(from: c)!
    }

    func save() {
        let d = UserDefaults.standard
        d.set(q1End, forKey: "q1End")
        d.set(q2End, forKey: "q2End")
        d.set(q3End, forKey: "q3End")
        d.set(q4End, forKey: "q4End")
    }

    func update() {
        let now = Date()
        let quarters = [(1, q1End), (2, q2End), (3, q3End), (4, q4End)]

        if let next = quarters.first(where: { $0.1 > now }) {
            currentQuarter = next.0
            currentQuarterEnd = next.1
        } else {
            currentQuarter = 4
            currentQuarterEnd = q4End
        }

        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: currentQuarterEnd)
        daysRemaining    = max(0, components.day    ?? 0)
        hoursRemaining   = max(0, components.hour   ?? 0)
        minutesRemaining = max(0, components.minute ?? 0)
    }

    deinit { timer?.invalidate() }
}
