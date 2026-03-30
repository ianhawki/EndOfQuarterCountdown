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

    private var timer: Timer?

    init() {
        let defaults = UserDefaults.standard
        let year = Calendar.current.component(.year, from: Date())

        q1End = (defaults.object(forKey: "q1End") as? Date) ?? Self.date(month: 3,  day: 31, year: year)
        q2End = (defaults.object(forKey: "q2End") as? Date) ?? Self.date(month: 6,  day: 30, year: year)
        q3End = (defaults.object(forKey: "q3End") as? Date) ?? Self.date(month: 9,  day: 30, year: year)
        q4End = (defaults.object(forKey: "q4End") as? Date) ?? Self.date(month: 12, day: 31, year: year)

        update()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }
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

        // Pick the next quarter end that hasn't passed yet
        if let next = quarters.first(where: { $0.1 > now }) {
            currentQuarter = next.0
            currentQuarterEnd = next.1
        } else {
            // All quarters passed — stay on Q4
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
