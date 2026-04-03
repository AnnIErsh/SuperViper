import Foundation

final class DefaultTaskBootstrapService: TaskBootstrapService {
    private let repository: TaskRepository
    private let remoteService: RemoteTaskService
    private let defaults: UserDefaults
    private let key = "didBootstrapFromDummyJSON"

    init(
        repository: TaskRepository,
        remoteService: RemoteTaskService,
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.remoteService = remoteService
        self.defaults = defaults
    }

    func bootstrapIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        if defaults.bool(forKey: key) {
            completion(.success(()))
            return
        }

        repository.fetchTasks { [weak self] result in
            guard let self else {
                completion(.success(()))
                return
            }

            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let localTasks):
                if !localTasks.isEmpty {
                    defaults.set(true, forKey: key)
                    completion(.success(()))
                    return
                }

                remoteService.fetchInitialTasks { [weak self] remoteResult in
                    guard let self else {
                        completion(.success(()))
                        return
                    }

                    switch remoteResult {
                    case .failure(let error):
                        completion(.failure(error))

                    case .success(let remoteTasks):
                        upsert(remoteTasks, index: 0) { upsertResult in
                            switch upsertResult {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success:
                                self.defaults.set(true, forKey: self.key)
                                completion(.success(()))
                            }
                        }
                    }
                }
            }
        }
    }

    private func upsert(_ tasks: [TaskItem], index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        if index >= tasks.count {
            completion(.success(()))
            return
        }

        repository.upsertTask(tasks[index]) { [weak self] result in
            guard let self else {
                completion(.success(()))
                return
            }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                upsert(tasks, index: index + 1, completion: completion)
            }
        }
    }
}
