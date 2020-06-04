import XCTest
import struct HTTP.Response
@testable import Routing

final class RouteCollectionTests: XCTestCase {
    func testInit() {
        // Arrange
        let routes = RouteCollection()

        // Assert
        XCTAssertTrue(routes.isEmpty)
        XCTAssertEqual(routes.path, String(Route.pathComponentSeparator))
        XCTAssertTrue(routes.name.isEmpty)
    }

    func testInitWithAnotherRouteCollection() {
        // Arrange
        let routes1 = RouteCollection([
            Route(method: .GET) { request in Response() },
            Route(method: .GET, path: "/blog") { request in Response() }!,
            Route(method: .POST) { request in Response() },
            Route(method: .POST, path: "/blog") { request in Response() }!
        ])

        // Act
        let routes2 = RouteCollection(routes1)

        // Assert
        XCTAssertEqual(routes2.count, routes1.count)
        XCTAssertEqual(routes2[.GET].count, routes1[.GET].count)
        XCTAssertEqual(routes2[.POST].count, routes1[.POST].count)
        XCTAssertEqual(routes2.path, routes1.path)
        XCTAssertEqual(routes2.name, routes1.name)
        XCTAssertTrue(routes2[.GET].contains(Route(method: .GET) { request in Response() }))
        XCTAssertTrue(routes2[.GET].contains(Route(method: .GET, path: "/blog") { request in Response() }!))
        XCTAssertTrue(routes2[.POST].contains(Route(method: .POST) { request in Response() }))
        XCTAssertTrue(routes2[.POST].contains(Route(method: .POST, path: "/blog") { request in Response() }!))
    }

    func testInitWithAnotherRouteCollectionPathAndName() {
        // Arrange
        let path = "/blog"
        let name = "blog_"
        let routes1 = RouteCollection([
            Route(method: .GET) { request in Response() },
            Route(method: .POST) { request in Response() }
        ])

        // Act
        let routes2 = RouteCollection(routes1, path: path, name: name)!

        // Assert
        XCTAssertEqual(routes2.count, routes1.count)
        XCTAssertEqual(routes2.path, path)
        XCTAssertEqual(routes2.name, name)
    }

    func testInitWithAnotherRouteCollectionHavingPathAndName() {
        // Arrange
        let path = "/blog"
        let name = "blog_"
        let routes1 = RouteCollection([
            Route(method: .GET) { request in Response() },
            Route(method: .POST) { request in Response() }
        ], path: path, name: name)!

        // Act
        let routes2 = RouteCollection(routes1)

        // Assert
        XCTAssertEqual(routes2.count, routes1.count)
        XCTAssertEqual(routes2[.GET].count, routes1[.GET].count)
        XCTAssertEqual(routes2[.POST].count, routes1[.POST].count)
        XCTAssertEqual(routes2.path, routes1.path)
        XCTAssertEqual(routes2.name, routes1.name)
        XCTAssertEqual(routes2[.GET], [
            Route(method: .GET, path: "/blog") { request in Response() }!
        ])
        XCTAssertEqual(routes2[.POST], [
            Route(method: .POST, path: "/blog") { request in Response() }!
        ])
    }

    func testInitWithRoutes() {
        // Arrange
        let routes = RouteCollection([
            Route(method: .GET) { request in Response() },
            Route(method: .GET, path: "/blog") { request in Response() }!,
            Route(method: .POST) { request in Response() },
            Route(method: .POST, path: "/blog") { request in Response() }!
        ])

        // Assert
        XCTAssertEqual(routes.count, 2)
        XCTAssertTrue(routes[.GET].contains(Route(method: .GET) { request in Response() }))
        XCTAssertTrue(routes[.GET].contains(Route(method: .GET, path: "/blog") { request in Response() }!))
        XCTAssertTrue(routes[.POST].contains(Route(method: .POST) { request in Response() }))
        XCTAssertTrue(routes[.POST].contains(Route(method: .POST, path: "/blog") { request in Response() }!))
    }

    func testInitWithName() {
        // Arrange
        let name = "blog_"
        let routes = RouteCollection(name: name)!

        // Assert
        XCTAssertTrue(routes.isEmpty)
        XCTAssertEqual(routes.path, String(Route.pathComponentSeparator))
        XCTAssertEqual(routes.name, name)
    }

    func testInitWithEmptyPathAndName() {
        // Arrange
        let name = "blog_"
        let routes = RouteCollection(path: "", name: name)!

        // Assert
        XCTAssertTrue(routes.isEmpty)
        XCTAssertEqual(routes.path, String(Route.pathComponentSeparator))
        XCTAssertEqual(routes.name, name)
    }

    func testInitWithPathAndName() {
        // Arrange
        let path = "/blog"
        let name = "blog_"
        let routes = RouteCollection(path: path, name: name)!

        // Assert
        XCTAssertTrue(routes.isEmpty)
        XCTAssertEqual(routes.path, path)
        XCTAssertEqual(routes.name, name)
    }

    func testInitWithInvalidPathAndName() {
        // Arrange
        let path = "//blog"
        let name = "blog_"
        let routes = RouteCollection(path: path, name: name)

        // Assert
        XCTAssertNil(routes)
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
