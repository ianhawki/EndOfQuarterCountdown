import SwiftUI

struct QuarterView: View {
    @EnvironmentObject var model: QuarterModel
    @State private var showingEditor = false
    @State private var urlDraft = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            countdown
            Divider()

            if model.shouldWarnNextFY {
                nextFYWarning
                Divider()
            }

            if showingEditor {
                quarterEditor
            }

            footer
        }
        .frame(width: 340)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Q\(model.currentDisplayQuarter) · End of Quarter")
                        .font(.headline)
                    if !model.financialYear.isEmpty {
                        Text(model.financialYear)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .cornerRadius(4)
                    }
                }
                Text(formatted(model.currentQuarterEnd))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()

            // Sync button
            Button {
                Task { await model.fetchDates() }
            } label: {
                if model.isFetching {
                    ProgressView()
                        .scaleEffect(0.65)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "arrow.clockwise.icloud")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }
            .buttonStyle(.plain)
            .disabled(model.isFetching)
            .help("Sync dates from web")

            // Edit button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingEditor.toggle()
                }
            } label: {
                Image(systemName: showingEditor ? "checkmark.circle.fill" : "slider.horizontal.3")
                    .font(.title3)
                    .foregroundColor(showingEditor ? .green : .accentColor)
            }
            .buttonStyle(.plain)
            .help(showingEditor ? "Done" : "Edit quarter dates")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var countdown: some View {
        HStack(spacing: 8) {
            CountdownUnit(value: model.daysRemaining,    label: "DAYS")
            separator
            CountdownUnit(value: model.currentWeekNumber, label: "WEEK")
            separator
            CountdownUnit(value: model.weeksRemaining,   label: "WKS LEFT")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var nextFYWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("New FY dates needed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
            }
            Text("Fewer than 70 days until \(model.financialYear) Q1 ends. Sync or update your quarter dates to keep the countdown accurate.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button {
                    Task { await model.fetchDates() }
                } label: {
                    Label("Sync Now", systemImage: "arrow.clockwise.icloud")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(model.isFetching)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showingEditor = true }
                } label: {
                    Label("Edit Dates", systemImage: "slider.horizontal.3")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.07))
    }

    private var quarterEditor: some View {
        VStack(spacing: 0) {
            // Sync status
            HStack {
                if let error = model.fetchError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if let last = model.lastFetched {
                    Image(systemName: "checkmark.icloud")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Synced \(relativeTime(last))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "icloud.slash")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Not yet synced from web")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            // URL field
            VStack(alignment: .leading, spacing: 6) {
                Text("SYNC URL")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
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
                if !isValidURL(urlDraft) {
                    Text("Enter a valid http or https URL")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .onAppear { urlDraft = model.feedURLString }

            Divider()

            QuarterRow(label: rowLabel(1), date: $model.q1End, isCurrent: model.currentQuarter == 1)
            Divider().padding(.leading, 44)
            QuarterRow(label: rowLabel(2), date: $model.q2End, isCurrent: model.currentQuarter == 2)
            Divider().padding(.leading, 44)
            QuarterRow(label: rowLabel(3), date: $model.q3End, isCurrent: model.currentQuarter == 3)
            Divider().padding(.leading, 44)
            QuarterRow(label: rowLabel(4), date: $model.q4End, isCurrent: model.currentQuarter == 4)
            Divider().padding(.leading, 44)
            QuarterRow(label: rowLabel(5), date: $model.q5End, isCurrent: model.currentQuarter == 5)
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Toggle("Launch at Login", isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                ))
                .toggleStyle(.checkbox)
                .font(.caption)
                .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            Divider()

            HStack {
                Text(appVersion)
                    .font(.caption)
                    .foregroundColor(Color.secondary.opacity(0.6))
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Helpers

    private var separator: some View {
        Text(":")
            .font(.system(size: 22, weight: .light))
            .foregroundColor(.secondary)
            .padding(.bottom, 16)
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: date)
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Build the row label from the stored FY label + quarter display number.
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
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"]            as? String ?? "?"
        return "v\(version) (\(build))"
    }
}

// MARK: - Quarter Row

struct QuarterRow: View {
    let label: String
    @Binding var date: Date
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: isCurrent ? .bold : .regular, design: .rounded))
                .foregroundColor(isCurrent ? .accentColor : .secondary)
                .lineLimit(1)
                .frame(width: 72, alignment: .leading)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .background(isCurrent ? Color.accentColor.opacity(0.12) : Color.clear)
                .cornerRadius(5)

            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)

            Spacer()

            if isCurrent {
                Image(systemName: "arrow.left")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                Text("current")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isCurrent ? Color.accentColor.opacity(0.05) : Color.clear)
    }
}

// MARK: - Countdown Unit

struct CountdownUnit: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .kerning(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }
}
