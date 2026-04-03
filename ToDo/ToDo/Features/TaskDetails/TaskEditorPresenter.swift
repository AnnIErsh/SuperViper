import Combine
import Foundation
import SwiftUI

@MainActor
final class TaskEditorPresenter: ObservableObject {
    @Published var title: String
    @Published var details: String
    @Published var isCompleted: Bool
    @Published var errorMessage: String?

    let mode: TaskEditorMode

    private var lastSavedTitle: String
    private var lastSavedDetails: String
    private var lastSavedCompleted: Bool

    private let interactor: TaskEditorInteractorInput
    private let onFinish: (TaskItem) -> Void

    private var isCancelled = false
    private var isSaving = false
    private var autosaveWorkItem: DispatchWorkItem?

    init(
        mode: TaskEditorMode,
        interactor: TaskEditorInteractorInput,
        onFinish: @escaping (TaskItem) -> Void
    ) {
        self.mode = mode
        self.interactor = interactor
        self.onFinish = onFinish

        let initialValues: (title: String, details: String, isCompleted: Bool)
        switch mode {
        case .create:
            initialValues = ("", "", false)
        case .edit(let task):
            initialValues = (task.title, task.details, task.isCompleted)
        }

        title = initialValues.title
        details = initialValues.details
        isCompleted = initialValues.isCompleted

        lastSavedTitle = initialValues.title
        lastSavedDetails = initialValues.details
        lastSavedCompleted = initialValues.isCompleted
    }

    var screenTitle: String {
        switch mode {
        case .create:
            return "Новая задача"
        case .edit:
            return "Редактирование"
        }
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasChanges: Bool {
        title != lastSavedTitle ||
        details != lastSavedDetails ||
        isCompleted != lastSavedCompleted
    }

    func cancelTapped() {
        isCancelled = true
        autosaveWorkItem?.cancel()
    }

    func contentDidChange() {
        guard !isCancelled else {
            return
        }

        guard case .edit = mode else {
            return
        }

        autosaveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.autosaveIfNeeded()
        }

        autosaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    func autosaveIfNeeded() {
        guard !isCancelled, canSave, hasChanges, !isSaving else {
            return
        }

        isSaving = true

        interactor.save(
            mode: mode,
            title: title,
            details: details,
            isCompleted: isCompleted
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let task):
                    self.lastSavedTitle = task.title
                    self.lastSavedDetails = task.details
                    self.lastSavedCompleted = task.isCompleted
                    self.onFinish(task)

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }

                self.isSaving = false

                if self.hasChanges {
                    self.contentDidChange()
                }
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
