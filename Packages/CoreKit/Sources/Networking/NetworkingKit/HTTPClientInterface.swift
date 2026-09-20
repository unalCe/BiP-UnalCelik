import Foundation

public protocol HTTPClientInterface: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}
