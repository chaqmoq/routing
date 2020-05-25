import XCTest
import struct HTTP.Response
@testable import Routing

final class RouteCollectionTests: XCTestCase {
    func testInit() {
        // Arrange
        let routeCollection = RouteCollection()

        // Assert
        XCTAssertTrue(routeCollection.isEmpty)
    }

    func testInitWithAnotherCollection() {
        // Arrange
        let routeCollection1 = RouteCollection([
            Route(method: .GET) { request in Response() }!,
            Route(method: .GET, path: "/blog") { request in Response() }!,
            Route(method: .POST) { request in Response() }!,
            Route(method: .POST, path: "/blog") { request in Response() }!
        ])

        // Act
        let routeCollection2 = RouteCollection(routeCollection1)

        // Assert
        XCTAssertEqual(routeCollection1, routeCollection2)
        XCTAssertEqual(routeCollection2.count, 2)
    }

    func testInitWithRoutes() {
        // Arrange
        var routeCollection = RouteCollection([
            Route(method: .GET) { request in Response() }!,
            Route(method: .GET, path: "/blog") { request in Response() }!,
            Route(method: .POST) { request in Response() }!,
            Route(method: .POST, path: "/blog") { request in Response() }!
        ])

        // Assert
        XCTAssertEqual(routeCollection.count, 2)
        XCTAssertEqual(routeCollection[.GET], [
            Route(method: .GET) { request in Response() }!,
            Route(method: .GET, path: "/blog") { request in Response() }!]
        )
        XCTAssertEqual(routeCollection[.POST], [
            Route(method: .POST) { request in Response() }!,
            Route(method: .POST, path: "/blog") { request in Response() }!]
        )

        // Act
        routeCollection.remove([
            Route(method: .GET) { request in Response() }!,
            Route(method: .GET, path: "/blog") { request in Response() }!
        ])

        // Assert
        XCTAssertEqual(routeCollection.count, 2)
        XCTAssertTrue(routeCollection[.GET].isEmpty)
        XCTAssertEqual(routeCollection[.POST], [
            Route(method: .POST) { request in Response() }!,
            Route(method: .POST, path: "/blog") { request in Response() }!]
        )
    }

    func testInsertRouteWithSameName() {
        // Arrange
        var routeCollection = RouteCollection([
            Route(method: .GET, path: "/", name: "blog") { request in Response() }!
        ])

        // Act
        routeCollection.insert(Route(method: .GET, path: "/blog", name: "blog") { request in Response() }!)

        // Assert
        XCTAssertEqual(routeCollection.count, 1)
        XCTAssertEqual(routeCollection[.GET].count, 1)
        XCTAssertEqual(routeCollection[.GET].first?.path, "/")
    }

    func testAddPathPrefix() {
        // Arrange
        var routeCollection = RouteCollection([
            Route(method: .GET, path: "/", name: "index") { request in Response() }!,
            Route(method: .GET, path: "/blog", name: "blog_index") { request in Response() }!,
            Route(method: .GET, path: "/blog/sign-in") { request in Response() }!
        ])

        // Assert
        XCTAssertFalse(routeCollection.add(pathPrefix: "admin"))
        XCTAssertTrue(routeCollection.add(pathPrefix: "/admin"))
        XCTAssertEqual(routeCollection[.GET].count, 3)
        XCTAssertTrue(routeCollection[.GET].contains(where: { $0.path == "/admin" && $0.name == "index" }))
        XCTAssertTrue(routeCollection[.GET].contains(where: { $0.path == "/admin/blog" && $0.name == "blog_index" }))
        XCTAssertTrue(routeCollection[.GET].contains(where: { $0.path == "/admin/blog/sign-in" && $0.name == nil }))
    }

    func testAddNamePrefix() {
        // Arrange
        var routeCollection = RouteCollection([
            Route(method: .GET, path: "/", name: "index") { request in Response() }!,
            Route(method: .GET, path: "/blog", name: "blog_index") { request in Response() }!,
            Route(method: .GET, path: "/blog/sign-in") { request in Response() }!
        ])

        // Assert
        XCTAssertFalse(routeCollection.add(namePrefix: "admin%"))
        XCTAssertTrue(routeCollection.add(namePrefix: "admin_"))
        XCTAssertEqual(routeCollection[.GET].count, 3)
        XCTAssertTrue(routeCollection[.GET].contains(where: { $0.path == "/" && $0.name == "admin_index" }))
        XCTAssertTrue(routeCollection[.GET].contains(where: { $0.path == "/blog" && $0.name == "admin_blog_index" }))
        XCTAssertTrue(routeCollection[.GET].contains(where: { $0.path == "/blog/sign-in" && $0.name == "admin_" }))
    }
}
