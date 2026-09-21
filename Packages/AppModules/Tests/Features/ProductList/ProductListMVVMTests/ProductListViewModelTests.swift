import CommonKit
import PerformanceKitMocks
import ProductDomain
import ProductRepositoryMocks
import XCTest
@testable import ProductListMVVM

/// No DependencyEngine anywhere in this file. Collaborators arrive through
/// `init`, so the test is compile-time safe and shares no global state.
@MainActor
final class ProductListViewModelTests: XCTestCase {
    func test_onAppear_loadsAndMapsProducts() async {
        let sut = makeSUT(repository: StubProductRepository())

        sut.onAppear()
        await sut.settle()

        XCTAssertEqual(sut.state.value?.map(\.title), ["Apples", "Pork", "Peppers"])
    }

    func test_emptyResult_producesEmptyState() async {
        let sut = makeSUT(repository: StubProductRepository(products: .success([])))

        sut.onAppear()
        await sut.settle()

        XCTAssertEqual(sut.state, .empty)
    }

    func test_notFound_producesNonRetryableFailure() async {
        let sut = makeSUT(
            repository: StubProductRepository(products: .failure(DomainError.notFound))
        )

        sut.onAppear()
        await sut.settle()

        guard case .failed(let error) = sut.state else {
            return XCTFail("expected failure, got \(sut.state)")
        }
        XCTAssertFalse(error.isRetryable)
    }

    func test_offline_producesRetryableFailure() async {
        let sut = makeSUT(
            repository: StubProductRepository(products: .failure(DomainError.offline))
        )

        sut.onAppear()
        await sut.settle()

        guard case .failed(let error) = sut.state else {
            return XCTFail("expected failure, got \(sut.state)")
        }
        XCTAssertTrue(error.isRetryable)
    }

    /// The ViewModel emits an id and performs no navigation — which is what
    /// lets the same instance drive a UIKit push and a SwiftUI path append.
    func test_didSelectItem_emitsProductID_withoutNavigating() async {
        let sut = makeSUT(repository: StubProductRepository())
        var selected: String?
        sut.onSelectProduct = { selected = $0 }

        sut.onAppear()
        await sut.settle()
        sut.didSelectItem(at: 1)

        XCTAssertEqual(selected, "6_id_is_a_string")
    }

    func test_load_tracesTheFetch() async {
        let tracer = RecordingPerformanceTracer()
        let sut = ProductListViewModel(
            fetchProducts: FetchProducts(repository: StubProductRepository()),
            tracer: tracer
        )

        sut.onAppear()
        await sut.settle()

        XCTAssertEqual(tracer.samples(for: .productsFetch).map(\.outcome), [.completed])
    }

    func test_failedLoad_tracesAFailedFetch() async {
        let tracer = RecordingPerformanceTracer()
        let sut = ProductListViewModel(
            fetchProducts: FetchProducts(repository: StubProductRepository(products: .failure(DomainError.offline))),
            tracer: tracer
        )

        sut.onAppear()
        await sut.settle()

        XCTAssertEqual(tracer.samples(for: .productsFetch).map(\.outcome), [.failed])
    }

    func test_onAppear_isIgnoredOnceLoaded() async {
        let repository = StubProductRepository()
        let sut = makeSUT(repository: repository)

        sut.onAppear()
        await sut.settle()
        sut.onAppear()

        XCTAssertNotNil(sut.state.value, "a second onAppear must not reset to loading")
    }

    // MARK: - Helpers

    private func makeSUT(repository: StubProductRepository) -> ProductListViewModel {
        ProductListViewModel(fetchProducts: FetchProducts(repository: repository))
    }
}

@MainActor
extension ProductListViewModel {
    /// The ViewModel starts a detached `Task`; yield until it lands.
    /// TODO: replace with an injected scheduler once one exists.
    func settle() async {
        for _ in 0..<50 {
            if !state.isLoading, !state.isIdle { return }
            await Task.yield()
        }
    }
}
