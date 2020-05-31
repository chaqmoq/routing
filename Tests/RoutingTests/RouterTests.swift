import XCTest
import struct HTTP.Request
import struct HTTP.Response
@testable import Routing

final class RouterTests: XCTestCase {
    var router: Router!

    override func setUp() {
        super.setUp()

        // Arrange
        let routes = RouteCollection([
            Route(method: .OPTIONS, path: "/", name: "index") { request in Response() }!,
            Route(method: .GET, path: "/posts", name: "post_list") { request in Response() }!,
            Route(method: .DELETE, path: "/posts/{id<\\d+>}", name: "post_delete") { request in Response() }!,
            Route(method: .GET, path: "/blog/{page<\\d+>!1}", name: "blog_page") { request in Response() }!,
            Route(method: .GET, path: "/categories/{id<\\d+>?1}", name: "category_get") { request in Response() }!,
            Route(method: .HEAD, path: "/blog/{page<\\d+>}/posts/{id<\\d+>}", name: "blog_page_post_get") { request in Response() }!,
            Route(method: .GET, path: "/categories/{name}/posts/{id<\\d+>?1}", name: "category_post_get") { request in Response() }!,
            Route(method: .GET, path: "/tags/{name?}", name: "tag_get") { request in Response() }!
        ])
        let builder = RouteCollectionBuilder(routes: routes)
        router = Router(builder: builder)
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
        // Act
        var route = router.resolveRoute(named: "index")

        // Assert
        XCTAssertEqual(route?.name, "index")

        // Act
        route = router.resolveRoute(named: "")

        // Assert
        XCTAssertNil(route)

        // Act
        route = router.resolveRoute(named: "not_existing_name")

        // Assert
        XCTAssertNil(route)

        // Act
        route = router.resolveRoute(named: "post_delete", parameters: ["id": "1"])

        // Assert
        XCTAssertEqual(route?.name, "post_delete")

        // Act
        route = router.resolveRoute(named: "post_delete", parameters: .init())

        // Assert
        XCTAssertNil(route)

        // Act
        route = router.resolveRoute(named: "", parameters: .init())

        // Assert
        XCTAssertNil(route)

        // Act
        route = router.resolveRoute(named: "not_existing_name", parameters: .init())

        // Assert
        XCTAssertNil(route)

        // Arrange
        router.builder.routes = .init()

        // Act
        route = router.resolveRoute(named: "any_name")

        // Assert
        XCTAssertNil(route)

        // Act
        route = router.resolveRoute(named: "any_name", parameters: .init())

        // Assert
        XCTAssertNil(route)
    }

    func testGenerateURLForRoute() {
        // Act
        var url = router.generateURLForRoute(named: "post_list")

        // Assert
        XCTAssertEqual(url, URL(string: "/posts"))

        // Act
        url = router.generateURLForRoute(named: "post_list", parameters: ["id": "1"])

        // Assert
        XCTAssertEqual(url, URL(string: "/posts"))

        // Act
        url = router.generateURLForRoute(named: "post_list", query: ["filter": "latest"])

        // Assert
        XCTAssertEqual(url, URL(string: "/posts?filter=latest"))

        // Act
        url = router.generateURLForRoute(named: "post_list", parameters: ["id": "1"], query: ["filter": "latest"])

        // Assert
        XCTAssertEqual(url, URL(string: "/posts?filter=latest"))

        // Act
        url = router.generateURLForRoute(named: "post_delete")

        // Assert
        XCTAssertNil(url)

        // Act
        url = router.generateURLForRoute(named: "post_delete", parameters: ["id": "1"])

        // Assert
        XCTAssertEqual(url, URL(string: "/posts/1"))

        // Act
        url = router.generateURLForRoute(named: "post_delete", query: ["filter": "latest"])

        // Assert
        XCTAssertNil(url)

        // Act
        url = router.generateURLForRoute(named: "post_delete", parameters: ["id": "1"], query: ["filter": "latest"])

        // Assert
        XCTAssertEqual(url, URL(string: "/posts/1?filter=latest"))

        // Act
        url = router.generateURLForRoute(named: "category_get")

        // Assert
        XCTAssertEqual(url, URL(string: "/categories/1"))

        // Act
        url = router.generateURLForRoute(named: "category_get", parameters: ["id": "2"])

        // Assert
        XCTAssertEqual(url, URL(string: "/categories/2"))

        // Act
        url = router.generateURLForRoute(named: "category_get", query: ["filter": "latest"])

        // Assert
        XCTAssertEqual(url, URL(string: "/categories/1?filter=latest"))

        // Act
        url = router.generateURLForRoute(named: "category_get", parameters: ["id": "2"], query: ["filter": "latest"])

        // Assert
        XCTAssertEqual(url, URL(string: "/categories/2?filter=latest"))

        // Act
        url = router.generateURLForRoute(named: "blog_page")

        // Assert
        XCTAssertEqual(url, URL(string: "/blog/1"))

        // Act
        url = router.generateURLForRoute(named: "blog_page", parameters: ["page": "2"])

        // Assert
        XCTAssertEqual(url, URL(string: "/blog/2"))

        // Act
        url = router.generateURLForRoute(named: "blog_page", query: ["filter": "latest"])

        // Assert
        XCTAssertEqual(url, URL(string: "/blog/1?filter=latest"))

        // Act
        url = router.generateURLForRoute(named: "blog_page", parameters: ["page": "2"], query: ["filter": "latest"])

        // Assert
        XCTAssertEqual(url, URL(string: "/blog/2?filter=latest"))

        // Act
        url = router.generateURLForRoute(named: "tag_get")

        // Assert
        XCTAssertEqual(url, URL(string: "/tags"))

        // Act
        url = router.generateURLForRoute(named: "tag_get", parameters: ["name": "swift"])

        // Assert
        XCTAssertEqual(url, URL(string: "/tags/swift"))

        // Act
        url = router.generateURLForRoute(named: "tag_get", query: ["filter": "latest"])

        // Assert
        XCTAssertEqual(url, URL(string: "/tags?filter=latest"))

        // Act
        url = router.generateURLForRoute(named: "tag_get", parameters: ["name": "swift"], query: ["filter": "latest"])

        // Assert
        XCTAssertEqual(url, URL(string: "/tags/swift?filter=latest"))

        // Act
        url = router.generateURLForRoute(named: "not_existing_name")

        // Assert
        XCTAssertNil(url)
    }
}
