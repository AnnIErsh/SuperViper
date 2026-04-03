import Foundation

enum TaskEditorMode: Identifiable, Equatable {
    case create
    case edit(TaskItem)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let task):
            return "edit_\(task.id)"
        }
    }
}
