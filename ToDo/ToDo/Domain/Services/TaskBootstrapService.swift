import Foundation

protocol TaskBootstrapService {
    func bootstrapIfNeeded(completion: @escaping (Result<Void, Error>) -> Void)
}
