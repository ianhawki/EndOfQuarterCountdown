import WidgetKit
import SwiftUI

// MARK: - App Group (must match main app entitlements)
private let kAppGroup = "group.com.example.endofquartercountdown"

// MARK: - Colours (mirror main app DK tokens)
private extension Color {
    static let wkBg     = Color(red: 0.09, green: 0.09, blue: 0.14)
    static let wkAccent = Color(red: 0.28, green: 0.56, blue: 1.00)
    static let wkSec    = Color.white.opacity(0.50)
    static let wkTer    = Color.white.opacity(0.28)
}

private let wkGradient = LinearGradient(
    colors: [Color(red: 0.52, green: 0.78, blue: 1.00),
             Color(red: 0.22, green: 0.46, blue: 0.96)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Timeline entry

struct QuarterEntry: TimelineEntry {
    let date:           Date
    let daysRemaining:  Int
    let weeksRemaining: Int
    let quarterLabel:   String
    let financialYear:  String
    let progress:       Double
    let dayInQuarter:   Int
    let totalDays:      Int
    let fyEndDate:      Date?
    let shouldWarn:     Bool
}

// MARK: - Data builder

private func buildDate(y: Int, m: Int, d: Int) -> Date {
    var c = DateComponents()
    c.year = y; c.month = m; c.day = d; c.hour = 23; c.minute = 59; c.second = 59
    return Calendar.current.date(from: c) ?? Date()
}

private func buildEntry(for now: Date = Date()) -> QuarterEntry {
    let ud  = UserDefaults(suiteName: kAppGroup) ?? .standard
    let cal = Calendar.current
    let yr  = cal.component(.year, from: now)

    struct Spec { let key, fyKey: String; let q, fm, fd, fy: Int }
    let specs = [
        Spec(key: "q1c", fyKey: "q1FY", q: 1, fm: 3,  fd: 31, fy: yr),
        Spec(key: "q2c", fyKey: "q2FY", q: 2, fm: 6,  fd: 30, fy: yr),
        Spec(key: "q3c", fyKey: "q3FY", q: 3, fm: 9,  fd: 30, fy: yr),
        Spec(key: "q4c", fyKey: "q4FY", q: 4, fm: 12, fd: 31, fy: yr),
        Spec(key: "q5c", fyKey: "q5FY", q: 1, fm: 3,  fd: 31, fy: yr + 1),
    ]
    var ends: [Date]   = []
    var fys:  [String] = []
    for s in specs {
        if let dict = ud.dictionary(forKey: s.key) as? [String: Int],
           let y = dict["y"], let m = dict["m"], let d = dict["d"] {
            ends.append(buildDate(y: y, m: m, d: d))
        } else {
            ends.append(buildDate(y: s.fy, m: s.fm, d: s.fd))
        }
        fys.append(ud.string(forKey: s.fyKey) ?? "")
    }

    let idx      = ends.firstIndex(where: { $0 > now }) ?? ends.count - 1
    let endDate  = ends[idx]
    let fy       = fys[idx]
    let displayQ = idx == 4 ? 1 : idx + 1
    let label    = fy.isEmpty ? "Q\(displayQ)" : "\(fy) Q\(displayQ)"

    let todayStart = cal.startOfDay(for: now)
    let endStart   = cal.startOfDay(for: endDate)
    let days = max(0, cal.dateComponents([.day], from: todayStart, to: endStart).day ?? 0)

    let startDate: Date = {
        if idx == 0 { return cal.date(byAdding: .year, value: -1, to: ends.last!)! }
        return cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: ends[idx - 1]))!
    }()
    let startDay  = cal.startOfDay(for: startDate)
    let total     = max(1, cal.dateComponents([.day], from: startDay, to: endStart).day ?? 90)
    let elapsed   = max(0, cal.dateComponents([.day], from: startDay, to: todayStart).day ?? 0)
    let progress  = Double(min(elapsed, total)) / Double(total)

    return QuarterEntry(
        date: now, daysRemaining: days, weeksRemaining: days / 7,
        quarterLabel: label, financialYear: fy, progress: progress,
        dayInQuarter: max(1, elapsed + 1), totalDays: total,
        fyEndDate: ends.count > 3 ? ends[3] : nil,
        shouldWarn: idx == 4 && days < 70
    )
}

// MARK: - Provider

struct QuarterProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuarterEntry {
        QuarterEntry(date: .now, daysRemaining: 42, weeksRemaining: 6,
                     quarterLabel: "FY26 Q3", financialYear: "FY26",
                     progress: 0.65, dayInQuarter: 48, totalDays: 90,
                     fyEndDate: nil, shouldWarn: false)
    }
    func getSnapshot(in context: Context, completion: @escaping (QuarterEntry) -> Void) {
        completion(buildEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuarterEntry>) -> Void) {
        let midnight = Calendar.current.date(
            byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: .now))!
        completion(Timeline(entries: [buildEntry()], policy: .after(midnight)))
    }
}

// MARK: - Small widget (~141×141 pt)

struct SmallView: View {
    let e: QuarterEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if !e.financialYear.isEmpty {
                    Text(e.financialYear)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.wkAccent).cornerRadius(4)
                }
                Spacer()
                if e.shouldWarn {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange).font(.caption)
                }
            }
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(e.daysRemaining)")
                    .font(.custom("Arial-Black", size: 62))
                    .foregroundStyle(wkGradient)
                    .minimumScaleFactor(0.5).lineLimit(1)
                Text("d")
                    .font(.custom("Arial-Black", size: 22))
                    .foregroundColor(.wkSec)
                    .padding(.bottom, 7)
            }
            Text(e.quarterLabel)
                .font(.system(size: 10, weight: .semibold)).foregroundColor(.wkSec)
            Text("\(e.weeksRemaining) weeks remaining")
                .font(.system(size: 9)).foregroundColor(.wkTer)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.wkBg)
    }
}

// MARK: - Medium widget (~300×141 pt)

struct MediumView: View {
    let e: QuarterEntry
    var body: some View {
        HStack(spacing: 0) {
            // Left — countdown
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if !e.financialYear.isEmpty {
                        Text(e.financialYear)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.wkAccent).cornerRadius(4)
                    }
                    if e.shouldWarn {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange).font(.caption)
                    }
                    Spacer()
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(e.daysRemaining)")
                        .font(.custom("Arial-Black", size: 70))
                        .foregroundStyle(wkGradient)
                        .minimumScaleFactor(0.5).lineLimit(1)
                    Text(e.daysRemaining == 1 ? "DAY" : "DAYS")
                        .font(.custom("Arial-Black", size: 14))
                        .foregroundColor(.wkSec)
                        .padding(.bottom, 10)
                }
                Text(e.quarterLabel)
                    .font(.system(size: 10, weight: .semibold)).foregroundColor(.wkSec)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1).padding(.vertical, 12)

            // Right — stats
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("PROGRESS")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.wkTer).kerning(0.5)
                        Spacer()
                        Text("\(Int((e.progress * 100).rounded()))%")
                            .font(.system(size: 10, weight: .bold)).foregroundColor(.wkAccent)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.09))
                            RoundedRectangle(cornerRadius: 2).fill(wkGradient)
                                .frame(width: max(4, geo.size.width * e.progress))
                        }
                    }.frame(height: 4)
                    HStack {
                        Text("DAY \(e.dayInQuarter)").font(.system(size: 8)).foregroundColor(.wkTer)
                        Spacer()
                        Text("DAY \(e.totalDays)").font(.system(size: 8)).foregroundColor(.wkTer)
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 1) {
                    Text("WEEKS LEFT")
                        .font(.system(size: 8, weight: .semibold)).foregroundColor(.wkTer).kerning(0.5)
                    Text("\(e.weeksRemaining)")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                }
                Spacer()
                if let fyEnd = e.fyEndDate {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("FY ENDS")
                            .font(.system(size: 8, weight: .semibold)).foregroundColor(.wkTer).kerning(0.5)
                        Text(fyEnd, format: .dateTime.day().month(.abbreviated).year())
                            .font(.system(size: 11, weight: .semibold)).foregroundColor(.wkSec)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .background(Color.wkBg)
    }
}

// MARK: - Entry view dispatcher

struct EntryView: View {
    let entry: QuarterEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        switch family {
        case .systemSmall: SmallView(e: entry)
        default:           MediumView(e: entry)
        }
    }
}

// MARK: - Widget

struct EndOfQuarterWidget: Widget {
    let kind = "EndOfQuarterWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuarterProvider()) { entry in
            EntryView(entry: entry)
                .containerBackground(Color.wkBg, for: .widget)
        }
        .configurationDisplayName("Quarter Countdown")
        .description("Days remaining in the current financial quarter.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
