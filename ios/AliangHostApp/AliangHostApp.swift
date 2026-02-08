import SwiftUI
import AliangIOS

@main
@MainActor
struct AliangHostApp: App {
    private let dependencies = Dependencies()

    var body: some Scene {
        WindowGroup {
            AliangAppView(dependencies: dependencies)
        }
    }
}
