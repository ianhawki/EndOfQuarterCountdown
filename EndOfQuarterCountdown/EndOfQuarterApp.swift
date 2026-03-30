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
                Image(systemName: "calendar")
                Text("Q\(model.currentQuarter) · \(model.daysRemaining)d")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
        }
        .menuBarExtraStyle(.window)
    }
}
