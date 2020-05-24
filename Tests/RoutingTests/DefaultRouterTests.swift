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
            Route(method: .HEAD, path: "/blog/{page<\\d+>}/posts/{id<\\d+>}", name: "blog_page_post_get") { request in Response() }!,
            Route(method: .GET, path: "/categories/{name}/posts/{id<\\d+>?1}", name: "category_post_get") { request in Response() }!,
            Route(method: .GET, path: "/tags/{name?}", name: "tag_get") { request in Response() }!
        ])
        router = DefaultRouter(routeCollection: routeCollection)
    }

    func testResolveRouteWithEmptyPath() {
        // Arrange
        let method: Request.Method = .OPTIONS
        let name = "index"

        // Act
        let route = router.resolveRouteBy(method: method, uri: "/")

        // Assert
        XCTAssertEqual(route?.name, name)
    }

    func testResolveRouteWithStaticPath() {
        // Arrange
        let method: Request.Method = .GET
        let name = "post_list"

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/posts/")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/posts")

        // Assert
        XCTAssertEqual(route?.name, name)
    }

    func testResolveRouteWithRequiredParameter() {
        // Arrange
        let method: Request.Method = .DELETE
        let name = "post_delete"

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/posts/1")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/posts/1/")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/posts")

        // Assert
        XCTAssertNotEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/posts/a")

        // Assert
        XCTAssertNil(route)
    }

    func testResolveRouteWithForcedDefaultParameter() {
        // Arrange
        let method: Request.Method = .GET
        let name = "blog_page"

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/blog/")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/1")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/1/")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/a")

        // Assert
        XCTAssertNil(route)
    }

    func testResolveRouteWithOptionalDefaultParameter() {
        // Arrange
        let method: Request.Method = .GET
        let name = "category_get"

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/categories/")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/1")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/1/")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/a")

        // Assert
        XCTAssertNil(route)
    }

    func testResolveRouteWithMultipleParameters() {
        // Arrange
        let method: Request.Method = .HEAD
        let name = "blog_page_post_get"

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/blog/1/posts/2/")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/1/posts/2")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/blog/a/posts/a")

        // Assert
        XCTAssertNil(route)
    }

    func testResolveRouteWithOneRequiredAndOneOptionalDefaultParameters() {
        // Arrange
        let method: Request.Method = .GET
        let name = "category_post_get"

        // Act
        var route = router.resolveRouteBy(method: method, uri: "/categories/swift/posts/1/")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/swift/posts/1")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/swift/posts/")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/swift/posts")

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRouteBy(method: method, uri: "/categories/swift/posts/a")

        // Assert
        XCTAssertNil(route)
    }

    func testResolveRouteNamed() {
        // Arrange
        let name = "index"

        // Act
        var route = router.resolveRoute(named: name)

        // Assert
        XCTAssertEqual(route?.name, name)

        // Act
        route = router.resolveRoute(named: "")

        // Assert
        XCTAssertNil(route)

        // Act
        route = router.resolveRoute(named: "not_existing_name")

        // Assert
        XCTAssertNil(route)
    }

    func testGenerateURLForRouteNamed() {
        // Act
        var url = router.generateURLForRoute(named: "post_list")

        // Assert
        XCTAssertEqual(url?.path, "/posts")

        // Act
        url = router.generateURLForRoute(named: "post_delete")

        // Assert
        XCTAssertNil(url)

        // Act
        url = router.generateURLForRoute(named: "category_get")

        // Assert
        XCTAssertEqual(url?.path, "/categories/1")

        // Act
        url = router.generateURLForRoute(named: "blog_page")

        // Assert
        XCTAssertEqual(url?.path, "/blog/1")

        // Act
        url = router.generateURLForRoute(named: "tag_get")

        // Assert
        XCTAssertEqual(url?.path, "/tags")

        // Act
        url = router.generateURLForRoute(named: "not_existing_name")

        // Assert
        XCTAssertNil(url)
    }
}
