import Foundation

struct TaskItem: Identifiable, Equatable, Hashable {
    let id: Int
    var title: String
    var details: String
    var createdAt: Date
    var isCompleted: Bool
}
