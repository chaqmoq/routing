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
        XCTAssertEqual(routes1, routes2)
        XCTAssertEqual(routes2.count, 2)
    }

    func testInitWithRoutes() {
        // Arrange
        var routes = RouteCollection([
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
        var routes = RouteCollection([
            Route(method: .GET, path: "/", name: "blog") { request in Response() }!
        ])

        // Act
        routes.insert(Route(method: .GET, path: "/blog", name: "blog") { request in Response() }!)

        // Assert
        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes[.GET].count, 1)
        XCTAssertEqual(routes[.GET].first?.path, "/")
    }

    func testAddPathPrefix() {
        // Arrange
        var routes = RouteCollection([
            Route(method: .GET, path: "/", name: "index") { request in Response() }!,
            Route(method: .GET, path: "/blog", name: "blog_index") { request in Response() }!,
            Route(method: .GET, path: "/blog/sign-in") { request in Response() }!
        ])

        // Assert
        XCTAssertFalse(routes.add(pathPrefix: "admin"))

        XCTAssertTrue(routes.add(pathPrefix: "/admin"))
        XCTAssertEqual(routes[.GET].count, 3)
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/admin" && $0.name == "index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/admin/blog" && $0.name == "blog_index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/admin/blog/sign-in" && $0.name == nil }))

        XCTAssertTrue(routes.add(pathPrefix: "/dashboard/"))
        XCTAssertEqual(routes[.GET].count, 3)
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/dashboard/admin" && $0.name == "index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/dashboard/admin/blog" && $0.name == "blog_index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/dashboard/admin/blog/sign-in" && $0.name == nil }))
    }

    func testAddNamePrefix() {
        // Arrange
        var routes = RouteCollection([
            Route(method: .GET, path: "/", name: "index") { request in Response() }!,
            Route(method: .GET, path: "/blog", name: "blog_index") { request in Response() }!,
            Route(method: .GET, path: "/blog/sign-in") { request in Response() }!
        ])

        // Assert
        XCTAssertFalse(routes.add(namePrefix: "admin_%"))
        XCTAssertTrue(routes.add(namePrefix: "admin_"))
        XCTAssertEqual(routes[.GET].count, 3)
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/" && $0.name == "admin_index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/blog" && $0.name == "admin_blog_index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/blog/sign-in" && $0.name == "admin_" }))
    }

    func testAddPathAndNamePrefixes() {
        // Arrange
        var routes = RouteCollection([
            Route(method: .GET, path: "/", name: "index") { request in Response() }!,
            Route(method: .GET, path: "/blog", name: "blog_index") { request in Response() }!,
            Route(method: .GET, path: "/blog/sign-in") { request in Response() }!
        ])

        // Assert
        XCTAssertFalse(routes.add(pathPrefix: "admin", namePrefix: "admin_frontend_%"))

        XCTAssertTrue(routes.add(pathPrefix: "/admin/frontend", namePrefix: "admin_frontend_"))
        XCTAssertEqual(routes[.GET].count, 3)
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/admin/frontend" && $0.name == "admin_frontend_index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/admin/frontend/blog" && $0.name == "admin_frontend_blog_index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/admin/frontend/blog/sign-in" && $0.name == "admin_frontend_" }))

        XCTAssertTrue(routes.add(pathPrefix: "/dashboard/home/", namePrefix: "dashboard_home_"))
        XCTAssertEqual(routes[.GET].count, 3)
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/dashboard/home/admin/frontend" && $0.name == "dashboard_home_admin_frontend_index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/dashboard/home/admin/frontend/blog" && $0.name == "dashboard_home_admin_frontend_blog_index" }))
        XCTAssertTrue(routes[.GET].contains(where: { $0.path == "/dashboard/home/admin/frontend/blog/sign-in" && $0.name == "dashboard_home_admin_frontend_" }))
    }
}
