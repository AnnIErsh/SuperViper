import Foundation

final class TaskEditorInteractor: TaskEditorInteractorInput {
    private let repository: TaskRepository

    init(repository: TaskRepository) {
        self.repository = repository
    }

    func save(
        mode: TaskEditorMode,
        title: String,
        details: String,
        isCompleted: Bool,
        completion: @escaping (Result<TaskItem, Error>) -> Void
    ) {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .create:
            repository.nextTaskIdentifier { [weak self] idResult in
                guard let self else { return }

                switch idResult {
                case .failure(let error):
                    completion(.failure(error))

                case .success(let id):
                    let task = TaskItem(
                        id: id,
                        title: normalizedTitle,
                        details: normalizedDetails,
                        createdAt: Date(),
                        isCompleted: isCompleted
                    )

                    self.repository.upsertTask(task) { upsertResult in
                        switch upsertResult {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success:
                            completion(.success(task))
                        }
                    }
                }
            }

        case .edit(let oldTask):
            let task = TaskItem(
                id: oldTask.id,
                title: normalizedTitle,
                details: normalizedDetails,
                createdAt: oldTask.createdAt,
                isCompleted: isCompleted
            )

            repository.upsertTask(task) { upsertResult in
                switch upsertResult {
                case .failure(let error):
                    completion(.failure(error))
                case .success:
                    completion(.success(task))
                }
            }
        }
    }
}
