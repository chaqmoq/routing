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
            Route(method: .GET, path: "/posts/{id<\\d+>}", name: "post_get") { request in Response() }!,
            Route(method: .HEAD, path: "/blog", name: "blog_index") { request in Response() }!,
            Route(method: .OPTIONS, path: "/", name: "index") { request in Response() }!,
            Route(method: .PATCH, path: "/posts/{id<\\d+>}", name: "post_update") { request in Response() }!,
            Route(method: .POST, path: "/posts", name: "post_create") { request in Response() }!,
            Route(method: .PUT, path: "/posts/{id<\\d+>}", name: "post_update") { request in Response() }!
        ])
        router = DefaultRouter(routeCollection: routeCollection)
    }

    func testResolveRouteWithRequiredParameter() {
        // Act
        var route = router.resolveRouteBy(method: .DELETE, uri: "/posts/1")

        // Assert
        XCTAssertEqual(route?.method, .DELETE)
        XCTAssertEqual(route?.path, "/posts/{id<\\d+>}")
        XCTAssertEqual(route?.name, "post_delete")

        // Act
        route = router.resolveRouteBy(method: .DELETE, uri: "/posts/a")

        // Assert
        XCTAssertNil(route)
    }
}
