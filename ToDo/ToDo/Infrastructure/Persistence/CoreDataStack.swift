import CoreData
import Foundation

final class CoreDataStack {
    let container: NSPersistentContainer

    init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "ToDoModel", managedObjectModel: model)

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "TaskEntity"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .integer64AttributeType
        id.isOptional = false

        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = false

        let details = NSAttributeDescription()
        details.name = "details"
        details.attributeType = .stringAttributeType
        details.isOptional = false

        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = false

        let isCompleted = NSAttributeDescription()
        isCompleted.name = "isCompleted"
        isCompleted.attributeType = .booleanAttributeType
        isCompleted.isOptional = false

        entity.properties = [id, title, details, createdAt, isCompleted]
        entity.uniquenessConstraints = [["id"]]

        model.entities = [entity]
        return model
    }
}
