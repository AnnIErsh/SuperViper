import Foundation
import Testing
@testable import ToDo

@Suite("ServiceLocator")
struct ServiceLocatorTests {
    @Test("singleton scope returns same instance")
    func singletonScope() {
        let locator = ServiceLocator()
        locator.register(MockService.self, scope: .singleton) { _ in MockService() }
        
        let first = locator.resolve(MockService.self)
        let second = locator.resolve(MockService.self)
        
        #expect(first === second)
    }
    
    @Test("transient scope returns new instances")
    func transientScope() {
        let locator = ServiceLocator()
        locator.register(MockService.self) { _ in MockService() }
        
        let first = locator.resolve(MockService.self)
        let second = locator.resolve(MockService.self)
        
        #expect(first !== second)
    }
}

@MainActor
@Suite("TaskEditorInteractor")
struct TaskEditorInteractorTests {
    @Test("create mode trims and stores task")
    func createMode() {
        let repository = EditorRepositoryMock(nextID: 42)
        let interactor = TaskEditorInteractor(repository: repository)
        
        let result: Result<TaskItem, Error> = waitForResult { completion in
            interactor.save(mode: .create, title: "  New Task  ", details: "  Details  ", isCompleted: true) { result in
                completion(result)
            }
        }
        
        switch result {
        case .failure(let error):
            Issue.record("Unexpected error: \(error)")
        case .success(let task):
            #expect(task.id == 42)
            #expect(task.title == "New Task")
            #expect(task.details == "Details")
            #expect(task.isCompleted)
            #expect(repository.saved.last == task)
        }
    }
    
    @Test("edit mode preserves id and createdAt")
    func editMode() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let source = TaskItem(id: 7, title: "Old", details: "Old details", createdAt: createdAt, isCompleted: false)
        
        let repository = EditorRepositoryMock(nextID: 100)
        let interactor = TaskEditorInteractor(repository: repository)
        
        let result: Result<TaskItem, Error> = waitForResult { completion in
            interactor.save(mode: .edit(source), title: "Updated", details: "Updated details", isCompleted: true) { result in
                completion(result)
            }
        }
        
        switch result {
        case .failure(let error):
            Issue.record("Unexpected error: \(error)")
        case .success(let task):
            #expect(task.id == source.id)
            #expect(task.createdAt == source.createdAt)
            #expect(task.title == "Updated")
            #expect(task.details == "Updated details")
            #expect(task.isCompleted)
        }
    }
}

@MainActor
@Suite("TaskListPresenter")
struct TaskListPresenterTests {
    @Test("onAppear loads once")
    func onAppearLoadsOnce() {
        let interactor = TaskListInteractorMock()
        let presenter = TaskListPresenter(interactor: interactor)
        
        presenter.onAppear()
        presenter.onAppear()
        
        #expect(interactor.loadCalls == 1)
    }
    
    @Test("filters by title and details")
    func filtersByQuery() {
        let interactor = TaskListInteractorMock()
        let presenter = TaskListPresenter(interactor: interactor)
        
        presenter.didLoadTasks([
            TaskItem(id: 1, title: "Workout", details: "Gym", createdAt: .now, isCompleted: false),
            TaskItem(id: 2, title: "Shopping", details: "Buy milk", createdAt: .now, isCompleted: false)
        ])
        
        presenter.query = "milk"
        
        #expect(presenter.filteredTasks.count == 1)
        #expect(presenter.filteredTasks.first?.id == 2)
    }
}

@Suite("DefaultTaskBootstrapService")
struct DefaultTaskBootstrapServiceTests {
    @Test("loads remote data when local storage is empty")
    func loadsRemoteData() {
        let repository = BootstrapRepositoryMock(localTasks: [])
        let remote = BootstrapRemoteMock(tasks: [sampleTask(1), sampleTask(2)])
        let defaults = isolatedDefaults()
        
        let service = DefaultTaskBootstrapService(repository: repository, remoteService: remote, defaults: defaults)
        let result: Result<Void, Error> = waitForResult { completion in
            service.bootstrapIfNeeded { result in
                completion(result)
            }
        }
        
        switch result {
        case .failure(let error):
            Issue.record("Unexpected error: \(error)")
        case .success:
            #expect(remote.fetchCalls == 1)
            #expect(repository.upsertCalls == 2)
            #expect(defaults.bool(forKey: "didBootstrapFromDummyJSON"))
        }
    }
    
    @Test("skips remote when bootstrap flag set")
    func skipsWhenFlagSet() {
        let repository = BootstrapRepositoryMock(localTasks: [])
        let remote = BootstrapRemoteMock(tasks: [sampleTask(1)])
        let defaults = isolatedDefaults()
        defaults.set(true, forKey: "didBootstrapFromDummyJSON")
        
        let service = DefaultTaskBootstrapService(repository: repository, remoteService: remote, defaults: defaults)
        
        _ = waitForResult { (completion: @escaping (Result<Void, Error>) -> Void) in
            service.bootstrapIfNeeded { result in
                completion(result)
            }
        }
        
        #expect(remote.fetchCalls == 0)
        #expect(repository.upsertCalls == 0)
    }
    
    private func sampleTask(_ id: Int) -> TaskItem {
        TaskItem(id: id, title: "Task \(id)", details: "Details", createdAt: .now, isCompleted: false)
    }
    
    private func isolatedDefaults() -> UserDefaults {
        let suite = "todo.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}

private final class MockService {}

private final class EditorRepositoryMock: TaskRepository {
    let nextID: Int
    private(set) var saved: [TaskItem] = []
    
    init(nextID: Int) {
        self.nextID = nextID
    }
    
    func fetchTasks(completion: @escaping (Result<[TaskItem], Error>) -> Void) {
        completion(.success([]))
    }
    
    func upsertTask(_ task: TaskItem, completion: @escaping (Result<Void, Error>) -> Void) {
        saved.append(task)
        completion(.success(()))
    }
    
    func deleteTask(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
    
    func nextTaskIdentifier(completion: @escaping (Result<Int, Error>) -> Void) {
        completion(.success(nextID))
    }
}

private final class TaskListInteractorMock: TaskListInteractorInput {
    private(set) var loadCalls = 0
    
    func loadTasks() {
        loadCalls += 1
    }
    
    func saveTask(_ task: TaskItem) {}
    
    func deleteTask(id: Int) {}
}

private final class BootstrapRepositoryMock: TaskRepository {
    private let localTasks: [TaskItem]
    private(set) var upsertCalls = 0
    
    init(localTasks: [TaskItem]) {
        self.localTasks = localTasks
    }
    
    func fetchTasks(completion: @escaping (Result<[TaskItem], Error>) -> Void) {
        completion(.success(localTasks))
    }
    
    func upsertTask(_ task: TaskItem, completion: @escaping (Result<Void, Error>) -> Void) {
        upsertCalls += 1
        completion(.success(()))
    }
    
    func deleteTask(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
    
    func nextTaskIdentifier(completion: @escaping (Result<Int, Error>) -> Void) {
        completion(.success(1))
    }
}

private final class BootstrapRemoteMock: RemoteTaskService {
    let tasks: [TaskItem]
    private(set) var fetchCalls = 0
    
    init(tasks: [TaskItem]) {
        self.tasks = tasks
    }
    
    func fetchInitialTasks(completion: @escaping (Result<[TaskItem], Error>) -> Void) {
        fetchCalls += 1
        completion(.success(tasks))
    }
}

private enum TestWaitError: Error {
    case timeout
}

private func waitForResult<T>(
    timeout: TimeInterval = 2,
    operation: (@escaping (Result<T, Error>) -> Void) -> Void
) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    var output: Result<T, Error> = .failure(TestWaitError.timeout)
    
    operation { result in
        output = result
        semaphore.signal()
    }
    
    if semaphore.wait(timeout: .now() + timeout) == .timedOut {
        return .failure(TestWaitError.timeout)
    }
    
    return output
}
