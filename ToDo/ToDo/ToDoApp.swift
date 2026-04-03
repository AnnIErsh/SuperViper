import SwiftUI

@main
struct ToDoApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
    }
}
