import Foundation

protocol TaskEditorInteractorInput {
    func save(
        mode: TaskEditorMode,
        title: String,
        details: String,
        isCompleted: Bool,
        completion: @escaping (Result<TaskItem, Error>) -> Void
    )
}
