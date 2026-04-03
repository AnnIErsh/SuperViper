import Foundation

protocol TaskRepository {
    func fetchTasks(completion: @escaping (Result<[TaskItem], Error>) -> Void)
    func upsertTask(_ task: TaskItem, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteTask(id: Int, completion: @escaping (Result<Void, Error>) -> Void)
    func nextTaskIdentifier(completion: @escaping (Result<Int, Error>) -> Void)
}
