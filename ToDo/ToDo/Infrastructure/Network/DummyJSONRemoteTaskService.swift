import Foundation

final class DummyJSONRemoteTaskService: RemoteTaskService {
    private let session: URLSession
    private let endpoint = URL(string: "https://dummyjson.com/todos")

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchInitialTasks(completion: @escaping (Result<[TaskItem], Error>) -> Void) {
        guard let endpoint else {
            completion(.failure(NSError(domain: "DummyJSONRemoteTaskService", code: 2)))
            return
        }

        session.dataTask(with: endpoint) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data else {
                completion(.failure(NSError(domain: "DummyJSONRemoteTaskService", code: 3)))
                return
            }

            do {
                let tasks = try self.parseTasks(from: data)
                completion(.success(tasks))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func parseTasks(from data: Data) throws -> [TaskItem] {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let todos = root["todos"] as? [[String: Any]]
        else {
            throw NSError(domain: "DummyJSONRemoteTaskService", code: 1)
        }

        return todos.compactMap { item in
            guard
                let id = item["id"] as? Int,
                let todo = item["todo"] as? String,
                let completed = item["completed"] as? Bool
            else {
                return nil
            }

            return TaskItem(
                id: id,
                title: todo,
                details: "Импортировано из dummyjson",
                createdAt: Date(timeIntervalSince1970: TimeInterval(1_700_000_000 + id * 3600)),
                isCompleted: completed
            )
        }
    }
}
