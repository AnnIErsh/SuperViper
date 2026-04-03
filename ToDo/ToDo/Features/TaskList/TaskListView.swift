import SwiftUI
import UIKit

struct TaskListView: View {
    @StateObject private var presenter: TaskListPresenter
    @State private var isKeyboardVisible = false
    @State private var editingTask: TaskItem?
    @State private var isCreatingTask = false
    @State private var selectedTaskForMenu: TaskItem?

    private let router: TaskListRouting

    init(presenter: TaskListPresenter, router: TaskListRouting) {
        _presenter = StateObject(wrappedValue: presenter)
        self.router = router
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Задачи")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                searchBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                if presenter.filteredTasks.isEmpty, !presenter.isLoading {
                    ContentUnavailableView(
                        "Нет задач",
                        systemImage: "checklist",
                        description: Text("Добавьте первую задачу через кнопку внизу")
                    )
                } else {
                    List(presenter.filteredTasks) { task in
                        TaskRowView(
                            task: task,
                            isInteractionEnabled: !isKeyboardVisible,
                            onToggleCompletion: {
                                presenter.toggleCompletion(task)
                            },
                            onOpen: {
                                editingTask = task
                            },
                            onHighlight: {
                                selectedTaskForMenu = task
                            }
                        )
                        .listRowBackground(Color.black)
                        .listRowSeparatorTint(Color.white.opacity(0.16))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                presenter.toggleCompletion(task)
                            } label: {
                                Label("Выполнено", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                presenter.deleteTask(task)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .blur(radius: selectedTaskForMenu == nil ? 0 : 3)
            .task {
                presenter.onAppear()
            }
            .overlay {
                if presenter.isLoading {
                    ProgressView()
                        .tint(.yellow)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !isKeyboardVisible {
                    bottomBar
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
            .alert(
                "Ошибка",
                isPresented: Binding(
                    get: { presenter.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
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
            .navigationDestination(item: $editingTask) { task in
                router.makeTaskEditorModule(mode: .edit(task)) { updatedTask in
                    presenter.didSaveTaskFromEditor(updatedTask)
                }
            }
            .navigationDestination(isPresented: $isCreatingTask) {
                router.makeTaskEditorModule(mode: .create) { task in
                    presenter.didSaveTaskFromEditor(task)
                }
            }
            .overlay {
                if let selectedTaskForMenu {
                    selectedOverlay(for: selectedTaskForMenu)
                        .transition(.opacity)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search", text: $presenter.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !presenter.query.isEmpty {
                Button {
                    presenter.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var bottomBar: some View {
        ZStack {
            Text("\(presenter.tasks.count) Задач")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            HStack {
                Spacer()

                Button {
                    isCreatingTask = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(.yellow)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground).opacity(0.95))
        .overlay(alignment: .top) {
            Divider().background(Color.white.opacity(0.14))
        }
    }

    private func selectedOverlay(for task: TaskItem) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.24))
                .ignoresSafeArea()
                .onTapGesture {
                    selectedTaskForMenu = nil
                }

            VStack(spacing: 12) {
                SelectedTaskCard(task: task)
                    .padding(.horizontal, 20)

                VStack(spacing: 0) {
                    Button {
                        selectedTaskForMenu = nil
                        editingTask = task
                    } label: {
                        menuRow(title: "Редактировать", icon: "square.and.pencil")
                    }

                    Divider().background(Color.black.opacity(0.12))

                    Button {
                        share(task: task)
                    } label: {
                        menuRow(title: "Поделиться", icon: "square.and.arrow.up")
                    }

                    Divider().background(Color.black.opacity(0.12))

                    Button(role: .destructive) {
                        presenter.deleteTask(task)
                        selectedTaskForMenu = nil
                    } label: {
                        menuRow(title: "Удалить", icon: "trash", isDestructive: true)
                    }
                }
                .background(Color(red: 0.78, green: 0.78, blue: 0.80))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: 360)
        }
    }

    private func menuRow(title: String, icon: String, isDestructive: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(isDestructive ? Color.red : Color.black)
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(isDestructive ? Color.red : Color.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func share(task: TaskItem) {
        let message = [task.title, task.details].filter { !$0.isEmpty }.joined(separator: "\n")
        let controller = UIActivityViewController(activityItems: [message], applicationActivities: nil)

        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return
        }

        controller.popoverPresentationController?.sourceView = root.view
        root.present(controller, animated: true)
    }
}

private struct TaskRowView: View {
    let task: TaskItem
    let isInteractionEnabled: Bool
    let onToggleCompletion: () -> Void
    let onOpen: () -> Void
    let onHighlight: () -> Void

    private var showsDetails: Bool {
        !task.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggleCompletion) {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.yellow : Color.gray.opacity(0.7), lineWidth: 2.2)

                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.yellow)
                    }
                }
                .frame(width: 30, height: 30)
                .frame(width: 44, height: 44, alignment: .top)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isInteractionEnabled)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(task.isCompleted ? .gray : .white)
                        .strikethrough(task.isCompleted, color: .gray)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if showsDetails {
                        Text(task.details)
                            .font(.body)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text(task.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isInteractionEnabled)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.35)
                .onEnded { _ in
                    if isInteractionEnabled {
                        onHighlight()
                    }
                }
        )
    }
}

private struct SelectedTaskCard: View {
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(task.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .strikethrough(task.isCompleted, color: .gray)

            if !task.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(task.details)
                    .font(.body)
                    .foregroundStyle(.gray)
                    .lineLimit(3)
            }

            Text(task.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
