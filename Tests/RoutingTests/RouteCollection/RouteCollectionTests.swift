import XCTest
import struct HTTP.Response
@testable import Routing

final class RouteCollectionTests: XCTestCase {
    func testInit() {
        // Act
        let routes = RouteCollection()

        // Assert
        XCTAssertTrue(routes.isEmpty)
        XCTAssertEqual(routes.path, String(Route.pathComponentSeparator))
        XCTAssertTrue(routes.name.isEmpty)
    }

    func testInitWithAnotherRouteCollection() {
        // Arrange
        let path = "/blog"
        let routes1 = RouteCollection([
            Route(method: .GET, path: path) { _ in Response() }!,
            Route(method: .POST, path: path) { _ in Response() }!
        ])

        // Act
        let routes2 = RouteCollection(routes1)

        // Assert
        XCTAssertEqual(routes2.count, 2)
        XCTAssertEqual(routes2[.GET].count, 1)
        XCTAssertEqual(routes2[.POST].count, 1)
        XCTAssertTrue(routes2[.GET].contains(where: { $0.path == "/blog" && $0.name == "" }))
        XCTAssertTrue(routes2[.POST].contains(where: { $0.path == "/blog" && $0.name == "" }))
        XCTAssertEqual(routes2.path, String(Route.pathComponentSeparator))
        XCTAssertTrue(routes2.name.isEmpty)
    }

    func testInitWithAnotherRouteCollectionPathAndName() {
        // Arrange
        let path = "/blog"
        let name = "blog_"
        let routes1 = RouteCollection([
            Route(method: .GET) { _ in Response() },
            Route(method: .POST) { _ in Response() }
        ])

        // Act
        let routes2 = RouteCollection(routes1, path: path, name: name)!

        // Assert
        XCTAssertEqual(routes2.count, 1)
        XCTAssertEqual(routes2[routes2.first!.key].filter({ $0.path == path && $0.name == name }).count, 1)
        XCTAssertEqual(routes2.path, path)
        XCTAssertEqual(routes2.name, name)
    }

    func testInitWithPathNameAndAnotherRouteCollectionWithPathAndName() {
        // Arrange
        let routes1 = RouteCollection(path: "/blog", name: "blog_")!

        // Act
        let routes2 = RouteCollection(routes1, path: "/posts", name: "post_")!

        // Assert
        XCTAssertEqual(routes2.count, 0)
        XCTAssertEqual(routes2.path, "/blog/posts")
        XCTAssertEqual(routes2.name, "blog_post_")
    }

    func testInitWithRoutes() {
        // Act
        let routes = RouteCollection([
            Route(method: .GET, path: "/posts", name: "post_list") { _ in Response() }!,
            Route(method: .POST, path: "/posts", name: "post_create") { _ in Response() }!
        ])

        // Assert
        XCTAssertEqual(routes.count, 2)
        XCTAssertEqual(routes[.GET].count, 1)
        XCTAssertEqual(routes[.POST].count, 1)
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/posts" && $0.name == "post_list" }))
        XCTAssertTrue(routes[.POST].contains(where: { $0.path == "/posts" && $0.name == "post_create" }))
        XCTAssertEqual(routes.path, String(Route.pathComponentSeparator))
        XCTAssertTrue(routes.name.isEmpty)
    }

    func testInitWithRoutesPathAndName() {
        // Act
        let routes = RouteCollection([
            Route(method: .GET, path: "/posts", name: "post_list") { _ in Response() }!,
            Route(method: .POST, path: "/posts", name: "post_create") { _ in Response() }!
        ], path: "/blog", name: "blog_")!

        // Assert
        XCTAssertEqual(routes.count, 2)
        XCTAssertEqual(routes[.GET].count, 1)
        XCTAssertEqual(routes[.POST].count, 1)
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/blog/posts" && $0.name == "blog_post_list" }))
        XCTAssertTrue(routes[.POST].contains(where: { $0.path == "/blog/posts" && $0.name == "blog_post_create" }))
        XCTAssertEqual(routes.path, "/blog")
        XCTAssertEqual(routes.name, "blog_")
    }

    func testInitWithName() {
        // Arrange
        let name = "blog_"

        // Act
        let routes = RouteCollection(name: name)

        // Assert
        XCTAssertTrue(routes.isEmpty)
        XCTAssertEqual(routes.path, String(Route.pathComponentSeparator))
        XCTAssertEqual(routes.name, name)
    }

    func testInitWithInvalidPathAndName() {
        // Arrange
        let path = "//blog"
        let name = "blog_"

        // Act
        let routes = RouteCollection(path: path, name: name)

        // Assert
        XCTAssertNil(routes)
    }

    func testInitWithAnotherRouteCollectionInvalidPathAndName() {
        // Arrange
        let routes1 = RouteCollection()
        let path = "//blog"
        let name = "blog_"

        // Act
        let routes2 = RouteCollection(routes1, path: path, name: name)

        // Assert
        XCTAssertNil(routes2)
    }

    func testRemoveRoutes() {
        // Arrange
        var routes = RouteCollection([
            Route(method: .GET, path: "/posts", name: "post_list") { _ in Response() }!,
            Route(method: .POST, path: "/posts", name: "post_create") { _ in Response() }!
        ])

        // Act
        routes.remove([
            Route(method: .GET, name: "post_list") { _ in Response() },
            Route(method: .POST, name: "post_create") { _ in Response() }
        ])

        // Assert
        XCTAssertTrue(routes.isEmpty)
    }

    func testRemoveNonExistingRoute() {
        // Arrange
        var routes = RouteCollection([
            Route(method: .GET, path: "/posts", name: "post_list") { _ in Response() }!,
            Route(method: .POST, path: "/posts", name: "post_create") { _ in Response() }!
        ])

        // Act
        let route = routes.remove(Route(method: .GET, name: "post_list2") { _ in Response() })

        // Assert
        XCTAssertNil(route)
        XCTAssertEqual(routes.count, 2)
        XCTAssertEqual(routes[.GET].count, 1)
        XCTAssertEqual(routes[.POST].count, 1)
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/posts" && $0.name == "post_list" }))
        XCTAssertTrue(routes[.POST].contains(where: { $0.path == "/posts" && $0.name == "post_create" }))
    }
}
