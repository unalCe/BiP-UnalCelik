import Foundation

public protocol DependencyRegistration {
    static func register(to engine: DependencyEngine)
}

public extension Array where Element == DependencyRegistration.Type {
    func registerAll(to engine: DependencyEngine = .shared) {
        forEach { $0.register(to: engine) }
    }
}
