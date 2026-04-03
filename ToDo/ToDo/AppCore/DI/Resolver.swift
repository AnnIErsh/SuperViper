import Foundation

protocol Resolver: AnyObject {
    func resolve<Service>(_ type: Service.Type) -> Service
}
