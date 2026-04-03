import SwiftUI

final class AppContainer {
    let locator = ServiceLocator()

    init() {
        registerServices()
    }

    @MainActor
    func makeRootView() -> some View {
        TaskListRouter.makeModule(resolver: locator)
    }

    private func registerServices() {
        locator.register(CoreDataStack.self, scope: .singleton) { _ in
            CoreDataStack()
        }

        locator.register(TaskRepository.self, scope: .singleton) { resolver in
            CoreDataTaskRepository(stack: resolver.resolve(CoreDataStack.self))
        }

        locator.register(RemoteTaskService.self, scope: .singleton) { _ in
            DummyJSONRemoteTaskService()
        }

        locator.register(TaskBootstrapService.self, scope: .singleton) { resolver in
            DefaultTaskBootstrapService(
                repository: resolver.resolve(TaskRepository.self),
                remoteService: resolver.resolve(RemoteTaskService.self)
            )
        }
    }
}
