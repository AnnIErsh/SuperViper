import Foundation

protocol TaskListInteractorInput: AnyObject {
    func loadTasks()
    func saveTask(_ task: TaskItem)
    func deleteTask(id: Int)
}

protocol TaskListInteractorOutput: AnyObject {
    func didLoadTasks(_ tasks: [TaskItem])
    func didFailLoadingTasks(_ error: Error)
}

protocol TaskListRouting {
    func makeTaskEditorModule(mode: TaskEditorMode, onFinish: @escaping (TaskItem) -> Void) -> TaskEditorView
}
