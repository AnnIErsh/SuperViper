import SwiftUI

struct ContentView: View {
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    var body: some View {
        container.makeRootView()
            .hideKeyboardOnTap()
    }
}
