import SwiftUI

// MARK: - Design tokens
private enum DK {
    static let bg      = Color(red: 0.09, green: 0.09, blue: 0.14)
    static let card    = Color(red: 0.14, green: 0.14, blue: 0.20)
    static let divider = Color.white.opacity(0.08)
    static let accent  = Color(red: 0.28, green: 0.56, blue: 1.00)
    static let pri     = Color.white
    static let sec     = Color.white.opacity(0.50)
    static let ter     = Color.white.opacity(0.28)
    static let warnBg  = Color(red: 0.50, green: 0.28, blue: 0.04).opacity(0.40)
    static let warnFg  = Color(red: 1.00, green: 0.74, blue: 0.32)
}

private let blueGradient = LinearGradient(
    colors: [Color(red: 0.52, green: 0.78, blue: 1.00),
             Color(red: 0.22, green: 0.46, blue: 0.96)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Main View

struct QuarterView: View {
    @EnvironmentObject var model: QuarterModel
    @State private var showingEditor = false
    @State private var urlDraft = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            thinDivider
            countdownSection
            progressSection
            infoCards

            if model.shouldWarnNextFY {
                thinDivider
                nextFYWarning
            }

            if showingEditor {
                thinDivider
                quarterEditor
            }

            thinDivider
            footer
        }
        .frame(width: 340)
        .background(DK.bg)
        .preferredColorScheme(.dark)
    }

    // MARK: Header ─────────────────────────────────────────────────────────────

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("End of Quarter Countdown")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DK.pri)

                    if !model.financialYear.isEmpty {
                        Text(model.financialYear)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(DK.accent)
                            .cornerRadius(4)
                    }
                }
                Text("Q\(model.currentDisplayQuarter) FISCAL PERFORMANCE WINDOW")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(DK.sec)
                    .kerning(0.8)
            }

            Spacer()

            // Sync
            Button { Task { await model.fetchDates() } } label: {
                Group {
                    if model.isFetching {
                        ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(DK.sec)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(model.isFetching)
            .frame(width: 28, height: 28)
            .background(Color.white.opacity(0.07))
            .cornerRadius(6)
            .help("Sync dates from web")

            // Edit
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { showingEditor.toggle() }
            } label: {
                Image(systemName: showingEditor ? "checkmark" : "pencil")
                    .font(.system(size: 11))
                    .foregroundColor(showingEditor ? DK.accent : DK.sec)
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 28)
            .background(showingEditor ? DK.accent.opacity(0.20) : Color.white.opacity(0.07))
            .cornerRadius(6)
            .help(showingEditor ? "Done" : "Edit quarter dates")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    // MARK: Countdown ──────────────────────────────────────────────────────────

    private var countdownSection: some View {
        VStack(spacing: 5) {
            // Big number + unit
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text("\(model.daysRemaining)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(blueGradient)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text(model.daysRemaining == 1 ? "DAY" : "DAYS")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DK.sec)
                    .padding(.bottom, 12)
            }

            // Weeks secondary
            if model.weeksRemaining > 0 {
                Text("≈ \(model.weeksRemaining) \(model.weeksRemaining == 1 ? "week" : "weeks") remaining")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DK.sec)
            }

            // FY · Period label
            Text("\(model.financialYear.isEmpty ? "" : model.financialYear + " · ")Q\(model.currentDisplayQuarter) PERIOD")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DK.ter)
                .kerning(1.0)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: Progress bar ───────────────────────────────────────────────────────

    private var progressSection: some View {
        VStack(spacing: 7) {
            HStack {
                Text("QUARTER PROGRESS")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(DK.ter)
                    .kerning(0.8)
                Spacer()
                Text("\(Int((quarterProgress * 100).rounded()))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DK.accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.09))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(blueGradient)
                        .frame(width: max(6, geo.size.width * quarterProgress))
                }
            }
            .frame(height: 6)

            HStack {
                Text("DAY \(dayInQuarter)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(DK.ter)
                Spacer()
                Text("DAY \(totalDaysInQuarter)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(DK.ter)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    // MARK: Info cards ─────────────────────────────────────────────────────────

    private var infoCards: some View {
        HStack(spacing: 10) {
            infoCard(
                title: "NEXT MILESTONE",
                value: "\(model.financialYear) Q\(model.currentDisplayQuarter) End",
                sub: "In \(model.daysRemaining) \(model.daysRemaining == 1 ? "day" : "days")"
            )
            infoCard(
                title: "ACCURACY",
                value: model.lastFetched != nil ? "Web Sync" : "Manual",
                sub: syncSubLabel
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private func infoCard(title: String, value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(DK.ter)
                .kerning(0.8)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(DK.pri)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(sub)
                .font(.system(size: 10))
                .foregroundColor(DK.sec)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DK.card)
        .cornerRadius(10)
    }

    // MARK: Warning banner ─────────────────────────────────────────────────────

    private var nextFYWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DK.warnFg)
                    .font(.caption)
                Text("New FY dates needed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DK.warnFg)
            }
            Text("Fewer than 70 days until \(model.financialYear) Q1 ends. Sync or update your quarter dates to keep the countdown accurate.")
                .font(.caption)
                .foregroundColor(DK.warnFg.opacity(0.80))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button {
                    Task { await model.fetchDates() }
                } label: {
                    Label("Sync Now", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.75, green: 0.45, blue: 0.08))
                .disabled(model.isFetching)

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showingEditor = true }
                } label: {
                    Label("Edit Dates", systemImage: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(DK.warnFg)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DK.warnBg)
    }

    // MARK: Quarter editor ─────────────────────────────────────────────────────

    private var quarterEditor: some View {
        VStack(spacing: 0) {
            // Sync status
            HStack(spacing: 6) {
                if let error = model.fetchError {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.caption)
                    Text(error).font(.caption).foregroundColor(.orange)
                } else if let last = model.lastFetched {
                    Image(systemName: "checkmark.icloud").foregroundColor(DK.sec).font(.caption)
                    Text("Synced \(relativeTime(last))").font(.caption).foregroundColor(DK.sec)
                } else {
                    Image(systemName: "icloud.slash").foregroundColor(DK.sec).font(.caption)
                    Text("Not yet synced from web").font(.caption).foregroundColor(DK.sec)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            thinDivider

            // URL field
            VStack(alignment: .leading, spacing: 6) {
                Text("SYNC URL")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(DK.ter)
                    .kerning(1)
                HStack(spacing: 6) {
                    TextField("https://", text: $urlDraft)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                        .onSubmit { saveURL() }
                    Button("Save") { saveURL() }
                        .font(.caption)
                        .disabled(urlDraft == model.feedURLString || !isValidURL(urlDraft))
                }
                if !urlDraft.isEmpty && !isValidURL(urlDraft) {
                    Text("Enter a valid http or https URL")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .onAppear { urlDraft = model.feedURLString }

            thinDivider

            QuarterRow(label: rowLabel(1), date: $model.q1End, isCurrent: model.currentQuarter == 1)
            thinDivider.padding(.leading, 44)
            QuarterRow(label: rowLabel(2), date: $model.q2End, isCurrent: model.currentQuarter == 2)
            thinDivider.padding(.leading, 44)
            QuarterRow(label: rowLabel(3), date: $model.q3End, isCurrent: model.currentQuarter == 3)
            thinDivider.padding(.leading, 44)
            QuarterRow(label: rowLabel(4), date: $model.q4End, isCurrent: model.currentQuarter == 4)
            thinDivider.padding(.leading, 44)
            QuarterRow(label: rowLabel(5), date: $model.q5End, isCurrent: model.currentQuarter == 5)
        }
    }

    // MARK: Footer ─────────────────────────────────────────────────────────────

    private var footer: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { model.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            Text("Launch at Login")
                .font(.system(size: 11))
                .foregroundColor(DK.sec)

            Spacer()

            Text(appVersion)
                .font(.system(size: 9))
                .foregroundColor(DK.ter)
            Text("·")
                .font(.system(size: 9))
                .foregroundColor(DK.ter)
            Text("by")
                .font(.system(size: 9))
                .foregroundColor(DK.ter)
            Link("Ian Hawkins", destination: URL(string: "mailto:ian@hawkinsmultimedia.net")!)
                .font(.system(size: 9))
                .foregroundColor(DK.accent)

            Button("QUIT") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DK.ter)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.07))
                .cornerRadius(5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Computed helpers ───────────────────────────────────────────────────

    private var quarterProgress: Double {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: model.currentQuarterStart)
        let end   = cal.startOfDay(for: model.currentQuarterEnd)
        let today = cal.startOfDay(for: Date())
        let total   = cal.dateComponents([.day], from: start, to: end).day   ?? 90
        let elapsed = cal.dateComponents([.day], from: start, to: today).day ?? 0
        guard total > 0 else { return 0 }
        return Double(max(0, min(elapsed, total))) / Double(total)
    }

    private var dayInQuarter: Int {
        let cal     = Calendar.current
        let start   = cal.startOfDay(for: model.currentQuarterStart)
        let today   = cal.startOfDay(for: Date())
        let elapsed = cal.dateComponents([.day], from: start, to: today).day ?? 0
        return max(1, elapsed + 1)
    }

    private var totalDaysInQuarter: Int {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: model.currentQuarterStart)
        let end   = cal.startOfDay(for: model.currentQuarterEnd)
        return cal.dateComponents([.day], from: start, to: end).day ?? 90
    }

    private var syncSubLabel: String {
        if model.fetchError != nil           { return "Sync failed" }
        if let last = model.lastFetched      { return "Synced \(relativeTime(last))" }
        return "Not synced"
    }

    private var thinDivider: some View {
        Rectangle().fill(DK.divider).frame(height: 1)
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    private func rowLabel(_ slot: Int) -> String {
        let fy = model.fyLabel(for: slot)
        let q  = slot == 5 ? 1 : slot
        return fy.isEmpty ? "Q\(q)" : "\(fy) Q\(q)"
    }

    private func saveURL() {
        guard isValidURL(urlDraft) else { return }
        model.feedURLString = urlDraft
    }

    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme == "https" || url.scheme == "http"
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"]            as? String ?? "?"
        return "v\(v) (\(b))"
    }
}

// MARK: - Quarter Row ──────────────────────────────────────────────────────────

struct QuarterRow: View {
    let label: String
    @Binding var date: Date
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: isCurrent ? .bold : .regular, design: .rounded))
                .foregroundColor(isCurrent ? DK.accent : DK.sec)
                .lineLimit(1)
                .frame(width: 72, alignment: .leading)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .background(isCurrent ? DK.accent.opacity(0.15) : Color.clear)
                .cornerRadius(5)

            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)

            Spacer()

            if isCurrent {
                Image(systemName: "arrow.left").font(.caption2).foregroundColor(DK.accent)
                Text("current").font(.caption2).foregroundColor(DK.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isCurrent ? DK.accent.opacity(0.06) : Color.clear)
    }
}
