import Foundation
import NetworkingKit
import UIKit

/// Answers every request from the stubs a UI test launched the app with.
///
/// Image requests without a stub get a small generated image, so screens
/// render fully without touching the network. Anything else without a stub is
/// a 404, which surfaces as the app's generic error state.
public final class StubbedHTTPClient: HTTPClientInterface, @unchecked Sendable {
    private let stubs: [HTTPStub]
    private let lock = NSLock()
    private var callCounts: [String: Int] = [:]

    public init(stubs: [HTTPStub]) {
        self.stubs = stubs
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        let path = request.url.path

        guard let stub = stubs.first(where: { path.hasSuffix($0.path) }), !stub.replies.isEmpty else {
            if Self.isImage(path) { return HTTPResponse(statusCode: 200, body: Self.placeholderImage) }
            throw NetworkError.unacceptableStatus(code: 404, body: Data())
        }

        let reply: HTTPStub.Reply = lock.withLock {
            let index = callCounts[stub.path, default: 0]
            callCounts[stub.path] = index + 1
            return stub.replies[min(index, stub.replies.count - 1)]
        }

        switch reply {
        case .response(let status, let body):
            guard (200..<300).contains(status) else {
                throw NetworkError.unacceptableStatus(code: status, body: body)
            }
            return HTTPResponse(statusCode: status, body: body)
        case .offline:
            throw NetworkError.transport(URLError(.notConnectedToInternet))
        }
    }

    // MARK: - Private

    private static func isImage(_ path: String) -> Bool {
        ["jpg", "jpeg", "png"].contains((path as NSString).pathExtension.lowercased())
    }

    private static let placeholderImage: Data = {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8), format: format).pngData { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }()
}
