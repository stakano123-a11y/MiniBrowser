import SwiftUI

@main
@MainActor
struct MiniBrowserApp: App {
    @StateObject private var model = BrowserViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onOpenURL { url in
                    model.handleCallbackURL(url)
                }
        }
    }
}

