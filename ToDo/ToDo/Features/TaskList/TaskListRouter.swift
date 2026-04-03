import SwiftUI

struct TaskListRouter: TaskListRouting {
    let resolver: Resolver

    static func makeModule(resolver: Resolver) -> TaskListView {
        let interactor = TaskListInteractor(
            repository: resolver.resolve(TaskRepository.self),
            bootstrapService: resolver.resolve(TaskBootstrapService.self)
        )
        let presenter = TaskListPresenter(interactor: interactor)
        interactor.output = presenter

        let router = TaskListRouter(resolver: resolver)
        return TaskListView(presenter: presenter, router: router)
    }

    func makeTaskEditorModule(
        mode: TaskEditorMode,
        onFinish: @escaping (TaskItem) -> Void
    ) -> TaskEditorView {
        let interactor = TaskEditorInteractor(repository: resolver.resolve(TaskRepository.self))
        let presenter = TaskEditorPresenter(mode: mode, interactor: interactor, onFinish: onFinish)
        return TaskEditorView(presenter: presenter)
    }
}
