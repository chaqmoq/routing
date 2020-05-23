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
            Route(method: .OPTIONS, path: "/", name: "index") { request in Response() }!,
            Route(method: .GET, path: "/posts", name: "post_list") { request in Response() }!,
            Route(method: .DELETE, path: "/posts/{id<\\d+>}", name: "post_delete") { request in Response() }!,
            Route(method: .GET, path: "/blog/{page<\\d+>!1}", name: "blog_page") { request in Response() }!,
            Route(method: .GET, path: "/categories/{id<\\d+>?1}", name: "category_get") { request in Response() }!,
            Route(method: .HEAD, path: "/blog/{page<\\d+>}/posts/{id<\\d+>}", name: "blog_page_post_get") { request in Response() }!
        ])
        router = DefaultRouter(routeCollection: routeCollection)
    }

    func testResolveRouteWithEmptyPath() {
        // Arrange
        let method: Request.Method = .OPTIONS

        // Act
        let route = router.resolveRouteBy(method: method, uri: "/")

        // Assert
        XCTAssertEqual(route?.name, "index")
    }

    func testResolveRouteWithStaticPath() {
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

    func testResolveRouteWithMultipleParameters() {
        // Arrange
        let method: Request.Method = .HEAD

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/blog/1/posts/2/")

        // Assert
        XCTAssertEqual(route?.name, "blog_page_post_get")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/1/posts/2")

        // Assert
        XCTAssertEqual(route?.name, "blog_page_post_get")

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/a/posts/b")

        // Assert
        XCTAssertNil(route)
    }
}
