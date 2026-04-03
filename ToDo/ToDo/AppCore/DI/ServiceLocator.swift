import Foundation

final class ServiceLocator: Resolver {
    enum Scope {
        case transient
        case singleton
    }

    private typealias Factory = (Resolver) -> Any

    private var registrations: [ObjectIdentifier: Factory] = [:]
    private var singletonScopes: Set<ObjectIdentifier> = []
    private var singletons: [ObjectIdentifier: Any] = [:]

    func register<Service>(
        _ type: Service.Type,
        scope: Scope = .transient,
        factory: @escaping (Resolver) -> Service
    ) {
        let key = ObjectIdentifier(type)
        registrations[key] = { resolver in
            factory(resolver)
        }

        if scope == .singleton {
            singletonScopes.insert(key)
        } else {
            singletonScopes.remove(key)
            singletons.removeValue(forKey: key)
        }
    }

    func resolve<Service>(_ type: Service.Type) -> Service {
        let key = ObjectIdentifier(type)
        guard let factory = registrations[key] else {
            fatalError("Missing registration for \(String(describing: type))")
        }

        if singletonScopes.contains(key), let singleton = singletons[key] as? Service {
            return singleton
        }

        guard let service = factory(self) as? Service else {
            fatalError("Invalid registration for \(String(describing: type))")
        }

        if singletonScopes.contains(key) {
            singletons[key] = service
        }

        return service
    }
}
