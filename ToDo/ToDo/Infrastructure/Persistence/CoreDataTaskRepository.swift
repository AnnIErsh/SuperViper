import CoreData
import Foundation

final class CoreDataTaskRepository: TaskRepository {
    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func fetchTasks(completion: @escaping (Result<[TaskItem], Error>) -> Void) {
        perform({ context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "TaskEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            return try context.fetch(request).compactMap { object in
                guard
                    let title = object.value(forKey: "title") as? String,
                    let details = object.value(forKey: "details") as? String,
                    let createdAt = object.value(forKey: "createdAt") as? Date
                else {
                    return nil
                }

                return TaskItem(
                    id: Int(object.value(forKey: "id") as? Int64 ?? 0),
                    title: title,
                    details: details,
                    createdAt: createdAt,
                    isCompleted: object.value(forKey: "isCompleted") as? Bool ?? false
                )
            }
        }, completion: completion)
    }

    func upsertTask(_ task: TaskItem, completion: @escaping (Result<Void, Error>) -> Void) {
        perform({ context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "TaskEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %d", task.id)

            let object: NSManagedObject
            if let existing = try context.fetch(request).first {
                object = existing
            } else {
                guard let entity = NSEntityDescription.entity(forEntityName: "TaskEntity", in: context) else {
                    throw NSError(domain: "CoreDataTaskRepository", code: 1)
                }
                object = NSManagedObject(entity: entity, insertInto: context)
            }

            object.setValue(Int64(task.id), forKey: "id")
            object.setValue(task.title, forKey: "title")
            object.setValue(task.details, forKey: "details")
            object.setValue(task.createdAt, forKey: "createdAt")
            object.setValue(task.isCompleted, forKey: "isCompleted")

            if context.hasChanges {
                try context.save()
            }
        }) { result in
            completion(result.map { _ in () })
        }
    }

    func deleteTask(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        perform({ context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "TaskEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %d", id)

            if let object = try context.fetch(request).first {
                context.delete(object)
            }

            if context.hasChanges {
                try context.save()
            }
        }) { result in
            completion(result.map { _ in () })
        }
    }

    func nextTaskIdentifier(completion: @escaping (Result<Int, Error>) -> Void) {
        perform({ context in
            let request = NSFetchRequest<NSDictionary>(entityName: "TaskEntity")
            request.resultType = .dictionaryResultType

            let expression = NSExpressionDescription()
            expression.name = "maxId"
            expression.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "id")])
            expression.expressionResultType = .integer64AttributeType

            request.propertiesToFetch = [expression]
            request.fetchLimit = 1

            let result = try context.fetch(request).first
            let maxId = result?["maxId"] as? Int64 ?? 0

            // Keep locally created IDs in a high range so they never collide
            // with imported remote tasks during first-launch bootstrap.
            let localBase: Int64 = 1_000_000
            let next = max(maxId, localBase) + 1
            return Int(next)
        }, completion: completion)
    }

    private func perform<T>(
        _ block: @escaping (NSManagedObjectContext) throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let context = stack.container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        context.perform {
            do {
                let value = try block(context)
                completion(.success(value))
            } catch {
                context.rollback()
                completion(.failure(error))
            }
        }
    }
}
