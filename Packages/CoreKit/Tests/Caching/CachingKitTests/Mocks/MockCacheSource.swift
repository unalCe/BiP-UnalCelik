import CachingKit
import Foundation

/// The three closures `CacheAsideLoader.load` takes, as one mock.
final class MockCacheSource: @unchecked Sendable {
    struct Failure: Error {}

    var invokedRead = false
    var invokedReadCount = 0
    var stubbedReadResult: Result<CacheEntry<String>?, Error> = .success(nil)

    var invokedFetch = false
    var invokedFetchCount = 0
    var stubbedFetchResult: Result<String, Error> = .success("remote")

    var invokedWrite = false
    var invokedWriteCount = 0
    var invokedWriteParameters: (value: String, date: Date)?
    var invokedWriteParametersList: [(value: String, date: Date)] = []
    var stubbedWriteError: Error?

    func read() async throws -> CacheEntry<String>? {
        invokedRead = true
        invokedReadCount += 1
        return try stubbedReadResult.get()
    }

    func fetch() async throws -> String {
        invokedFetch = true
        invokedFetchCount += 1
        return try stubbedFetchResult.get()
    }

    func write(_ value: String, _ date: Date) async throws {
        invokedWrite = true
        invokedWriteCount += 1
        invokedWriteParameters = (value, date)
        invokedWriteParametersList.append((value, date))
        if let stubbedWriteError { throw stubbedWriteError }
    }
}
