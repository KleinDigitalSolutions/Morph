import SwiftUI

@main
struct MorphApp: App {
    @State private var stateManager = AppStateManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stateManager)
        }
    }
}
