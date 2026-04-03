import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var presenter: TaskEditorPresenter

    init(presenter: TaskEditorPresenter) {
        _presenter = StateObject(wrappedValue: presenter)
    }

    var body: some View {
        Form {
            Section("Название") {
                TextField("Введите задачу", text: $presenter.title)
            }

            Section("Описание") {
                TextEditor(text: $presenter.details)
                    .frame(minHeight: 140)
            }

            Section {
                Toggle("Выполнена", isOn: $presenter.isCompleted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle(presenter.screenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    presenter.autosaveIfNeeded()
                    dismiss()
                } label: {
                    Label("Назад", systemImage: "chevron.backward")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Отмена") {
                    presenter.cancelTapped()
                    dismiss()
                }
            }
        }
        .onChange(of: presenter.title) { _, _ in
            presenter.contentDidChange()
        }
        .onChange(of: presenter.details) { _, _ in
            presenter.contentDidChange()
        }
        .onChange(of: presenter.isCompleted) { _, _ in
            presenter.contentDidChange()
        }
        .alert(
            "Ошибка",
            isPresented: Binding(
                get: { presenter.errorMessage != nil },
                set: { value in
                    if !value {
                        presenter.clearError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                presenter.clearError()
            }
        } message: {
            Text(presenter.errorMessage ?? "Unknown error")
        }
        .onDisappear {
            presenter.autosaveIfNeeded()
        }
    }
}
