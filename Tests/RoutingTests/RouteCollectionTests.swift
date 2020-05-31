import XCTest
import struct HTTP.Response
@testable import Routing

final class RouteCollectionTests: XCTestCase {
    func testInit() {
        // Arrange
        let routes = RouteCollection()

        // Assert
        XCTAssertTrue(routes.isEmpty)
    }

    func testInitWithAnotherCollection() {
        // Arrange
        let routes1 = RouteCollection([
            Route(method: .GET) { request in Response() }!,
            Route(method: .GET, path: "/blog") { request in Response() }!,
            Route(method: .POST) { request in Response() }!,
            Route(method: .POST, path: "/blog") { request in Response() }!
        ])

        // Act
        let routes2 = RouteCollection(routes1)

        // Assert
        XCTAssertEqual(routes2.count, 2)
    }

    func testInitWithRoutes() {
        // Arrange
        let routes = RouteCollection([
            Route(method: .GET) { request in Response() }!,
            Route(method: .GET, path: "/blog") { request in Response() }!,
            Route(method: .POST) { request in Response() }!,
            Route(method: .POST, path: "/blog") { request in Response() }!
        ])

        // Assert
        XCTAssertEqual(routes.count, 2)
        XCTAssertEqual(routes[.GET], [
            Route(method: .GET) { request in Response() }!,
            Route(method: .GET, path: "/blog") { request in Response() }!]
        )
        XCTAssertEqual(routes[.POST], [
            Route(method: .POST) { request in Response() }!,
            Route(method: .POST, path: "/blog") { request in Response() }!]
        )

        // Act
        routes.remove([
            Route(method: .GET) { request in Response() }!,
            Route(method: .GET, path: "/blog") { request in Response() }!
        ])

        // Assert
        XCTAssertEqual(routes.count, 2)
        XCTAssertTrue(routes[.GET].isEmpty)
        XCTAssertEqual(routes[.POST], [
            Route(method: .POST) { request in Response() }!,
            Route(method: .POST, path: "/blog") { request in Response() }!]
        )
    }

    func testInsertRouteWithSameName() {
        // Arrange
        let routes = RouteCollection([
            Route(method: .GET, path: "/", name: "blog") { request in Response() }!
        ])

        // Act
        routes.insert(Route(method: .GET, path: "/blog", name: "blog") { request in Response() }!)

        // Assert
        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes[.GET].count, 1)
        XCTAssertEqual(routes[.GET].first?.path, "/")
    }
}
