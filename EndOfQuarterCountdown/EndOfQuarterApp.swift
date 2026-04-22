import SwiftUI

@main
struct EndOfQuarterApp: App {
    @StateObject private var model = QuarterModel()

    var body: some Scene {
        MenuBarExtra {
            QuarterView()
                .environmentObject(model)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: model.shouldWarnNextFY ? "exclamationmark.triangle.fill" : "calendar")
                    .foregroundColor(model.shouldWarnNextFY ? .orange : .primary)
                Text({
                    let days = "\(model.daysRemaining)\(model.useBusinessDays ? "bd" : "d")"
                    return model.financialYear.isEmpty
                        ? "Q\(model.currentDisplayQuarter) · \(days)"
                        : "\(model.financialYear) Q\(model.currentDisplayQuarter) · \(days)"
                }())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(model.shouldWarnNextFY ? .orange : .primary)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
