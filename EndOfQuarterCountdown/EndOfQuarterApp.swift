import SwiftUI
import CoreText

@main
struct EndOfQuarterApp: App {
    @StateObject private var model = QuarterModel()

    init() {
        // Register any custom fonts bundled inside the app (e.g. ObsidianGlass-Bold.ttf)
        if let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) {
            urls.forEach { CTFontManagerRegisterFontsForURL($0 as CFURL, .process, nil) }
        }
        if let urls = Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: nil) {
            urls.forEach { CTFontManagerRegisterFontsForURL($0 as CFURL, .process, nil) }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            QuarterView()
                .environmentObject(model)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: model.shouldWarnNextFY ? "exclamationmark.triangle.fill" : "calendar")
                    .foregroundColor(model.shouldWarnNextFY ? .orange : .primary)
                Text(model.financialYear.isEmpty
                     ? "Q\(model.currentDisplayQuarter) · \(model.daysRemaining)d"
                     : "\(model.financialYear) Q\(model.currentDisplayQuarter) · \(model.daysRemaining)d")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(model.shouldWarnNextFY ? .orange : .primary)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
