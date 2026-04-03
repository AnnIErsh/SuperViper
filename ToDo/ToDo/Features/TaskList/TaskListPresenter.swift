import Combine
import Foundation
import SwiftUI

@MainActor
final class TaskListPresenter: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published var query = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var editorMode: TaskEditorMode?

    private let interactor: TaskListInteractorInput
    private var didLoadInitially = false

    init(interactor: TaskListInteractorInput) {
        self.interactor = interactor
    }

    var filteredTasks: [TaskItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return tasks
        }

        return tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(query) ||
            task.details.localizedCaseInsensitiveContains(query)
        }
    }

    func onAppear() {
        guard !didLoadInitially else {
            return
        }

        didLoadInitially = true
        isLoading = true
        interactor.loadTasks()
    }

    func addTaskTapped() {
        editorMode = .create
    }

    func editTaskTapped(_ task: TaskItem) {
        editorMode = .edit(task)
    }

    func toggleCompletion(_ task: TaskItem) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        interactor.saveTask(updatedTask)
    }

    func deleteTask(_ task: TaskItem) {
        interactor.deleteTask(id: task.id)
    }

    func didSaveTaskFromEditor(_ task: TaskItem) {
        editorMode = nil
        interactor.saveTask(task)
    }

    func clearError() {
        errorMessage = nil
    }
}

extension TaskListPresenter: TaskListInteractorOutput {
    func didLoadTasks(_ tasks: [TaskItem]) {
        self.tasks = tasks
        isLoading = false
    }

    func didFailLoadingTasks(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }
}
