import Foundation

protocol RemoteTaskService {
    func fetchInitialTasks(completion: @escaping (Result<[TaskItem], Error>) -> Void)
}
