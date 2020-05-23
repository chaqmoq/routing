import XCTest
import struct HTTP.Request
import struct HTTP.Response
@testable import Routing

final class DefaultRouterTests: XCTestCase {
    var router: Router!

    override func setUp() {
        super.setUp()

        // Arrange
        let routeCollection = RouteCollection([
            Route(method: .DELETE, path: "/posts/{id<\\d+>}", name: "post_delete") { request in Response() }!,
            Route(method: .GET, path: "/blog/{page<\\d+>!1}", name: "blog_page") { request in Response() }!,
            Route(method: .GET, path: "/posts", name: "post_list") { request in Response() }!,
            Route(method: .GET, path: "/categories/{id<\\d+>?1}", name: "category_get") { request in Response() }!,
            Route(method: .HEAD, path: "/blog", name: "blog_index") { request in Response() }!,
            Route(method: .OPTIONS, path: "/", name: "index") { request in Response() }!,
            Route(method: .PATCH, path: "/posts/{id<\\d+>}", name: "post_update") { request in Response() }!,
            Route(method: .POST, path: "/posts", name: "post_create") { request in Response() }!,
            Route(method: .PUT, path: "/posts/{id<\\d+>}", name: "post_update") { request in Response() }!
        ])
        router = DefaultRouter(routeCollection: routeCollection)
    }

    func testResolveRouteWithRequiredParameter() {
        // Arrange
        let method: Request.Method = .DELETE

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/posts/1")

        // Assert
        XCTAssertEqual(route?.name, "post_delete")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/posts/1/")

        // Assert
        XCTAssertEqual(route?.name, "post_delete")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/posts")

        // Assert
        XCTAssertNotEqual(route?.name, "post_delete")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/posts/a")

        // Assert
        XCTAssertNil(route)
    }

    func testResolveRouteWithForcedDefaultParameter() {
        // Arrange
        let method: Request.Method = .GET

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/blog/")

        // Assert
        XCTAssertEqual(route?.name, "blog_page")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog")

        // Assert
        XCTAssertEqual(route?.name, "blog_page")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/1")

        // Assert
        XCTAssertEqual(route?.name, "blog_page")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/1/")

        // Assert
        XCTAssertEqual(route?.name, "blog_page")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/a")

        // Assert
        XCTAssertNil(route)
    }

    func testResolveRouteWithOptionalDefaultParameter() {
        // Arrange
        let method: Request.Method = .GET

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/categories/")

        // Assert
        XCTAssertEqual(route?.name, "category_get")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories")

        // Assert
        XCTAssertEqual(route?.name, "category_get")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/1")

        // Assert
        XCTAssertEqual(route?.name, "category_get")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/1/")

        // Assert
        XCTAssertEqual(route?.name, "category_get")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/a")

        // Assert
        XCTAssertNil(route)
    }

    func testResolveRouteWithoutParameters() {
        // Arrange
        let method: Request.Method = .GET

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/posts/")

        // Assert
        XCTAssertEqual(route?.name, "post_list")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/posts")

        // Assert
        XCTAssertEqual(route?.name, "post_list")
    }
}
