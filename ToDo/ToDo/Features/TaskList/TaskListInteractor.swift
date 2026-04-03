import Foundation

final class TaskListInteractor: TaskListInteractorInput {
    weak var output: TaskListInteractorOutput?

    private let repository: TaskRepository
    private let bootstrapService: TaskBootstrapService

    init(repository: TaskRepository, bootstrapService: TaskBootstrapService) {
        self.repository = repository
        self.bootstrapService = bootstrapService
    }

    func loadTasks() {
        bootstrapService.bootstrapIfNeeded { [weak self] bootstrapResult in
            guard let self else { return }

            switch bootstrapResult {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.output?.didFailLoadingTasks(error)
                }

            case .success:
                self.repository.fetchTasks { [weak self] fetchResult in
                    guard let self else { return }

                    DispatchQueue.main.async {
                        switch fetchResult {
                        case .success(let tasks):
                            self.output?.didLoadTasks(tasks)
                        case .failure(let error):
                            self.output?.didFailLoadingTasks(error)
                        }
                    }
                }
            }
        }
    }

    func saveTask(_ task: TaskItem) {
        repository.upsertTask(task) { [weak self] upsertResult in
            guard let self else { return }

            switch upsertResult {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.output?.didFailLoadingTasks(error)
                }

            case .success:
                self.repository.fetchTasks { [weak self] fetchResult in
                    guard let self else { return }

                    DispatchQueue.main.async {
                        switch fetchResult {
                        case .success(let tasks):
                            self.output?.didLoadTasks(tasks)
                        case .failure(let error):
                            self.output?.didFailLoadingTasks(error)
                        }
                    }
                }
            }
        }
    }

    func deleteTask(id: Int) {
        repository.deleteTask(id: id) { [weak self] deleteResult in
            guard let self else { return }

            switch deleteResult {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.output?.didFailLoadingTasks(error)
                }

            case .success:
                self.repository.fetchTasks { [weak self] fetchResult in
                    guard let self else { return }

                    DispatchQueue.main.async {
                        switch fetchResult {
                        case .success(let tasks):
                            self.output?.didLoadTasks(tasks)
                        case .failure(let error):
                            self.output?.didFailLoadingTasks(error)
                        }
                    }
                }
            }
        }
    }
}
