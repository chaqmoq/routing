import XCTest
import struct HTTP.Response
@testable import Routing

final class RouteCollectionBuilderTests: XCTestCase {
    var builder: RouteCollection.Builder!

    override func setUp() {
        super.setUp()

        // Arrange
        builder = RouteCollection.Builder()
    }

    func testDelete() {
        // Act
        let route = builder.delete("/posts/{id<\\d+>}", name: "post_delete") { _ in Response() }!

        // Assert
        XCTAssertEqual(builder.routes.count, 1)
        XCTAssertEqual(builder.routes[.DELETE].count, 1)
        XCTAssertTrue(builder.routes.has(route))
    }

    func testGet() {
        // Act
        let route = builder.get("/posts/{id<\\d+>}", name: "post_get") { _ in Response() }!

        // Assert
        XCTAssertEqual(builder.routes.count, 1)
        XCTAssertEqual(builder.routes[.GET].count, 1)
        XCTAssertTrue(builder.routes.has(route))
    }

    func testHead() {
        // Act
        let route = builder.head("/posts", name: "post_head") { _ in Response() }!

        // Assert
        XCTAssertEqual(builder.routes.count, 1)
        XCTAssertEqual(builder.routes[.HEAD].count, 1)
        XCTAssertTrue(builder.routes.has(route))
    }

    func testOptions() {
        // Act
        let route = builder.options("/posts", name: "post_options") { _ in Response() }!

        // Assert
        XCTAssertEqual(builder.routes.count, 1)
        XCTAssertEqual(builder.routes[.OPTIONS].count, 1)
        XCTAssertTrue(builder.routes.has(route))
    }

    func testPatch() {
        // Act
        let route = builder.patch("/posts/{id<\\d+>}", name: "post_update") { _ in Response() }!

        // Assert
        XCTAssertEqual(builder.routes.count, 1)
        XCTAssertEqual(builder.routes[.PATCH].count, 1)
        XCTAssertTrue(builder.routes.has(route))
    }

    func testPost() {
        // Act
        let route = builder.post("/posts", name: "post_create") { _ in Response() }!

        // Assert
        XCTAssertEqual(builder.routes.count, 1)
        XCTAssertEqual(builder.routes[.POST].count, 1)
        XCTAssertTrue(builder.routes.has(route))
    }

    func testPut() {
        // Act
        let route = builder.put("/posts/{id<\\d+>}", name: "post_update") { _ in Response() }!

        // Assert
        XCTAssertEqual(builder.routes.count, 1)
        XCTAssertEqual(builder.routes[.PUT].count, 1)
        XCTAssertTrue(builder.routes.has(route))
    }

    func testRequestWithMultipleMethods() {
        // Arrange
        let path = "/posts/{id<\\d+>}"

        // Act
        let routes = builder.request(path, methods: [.DELETE, .GET]) { _ in Response() }

        // Assert
        XCTAssertEqual(routes.count, 2)
        XCTAssertTrue(routes.contains(Route(method: .DELETE, path: path) { _ in Response() }!))
        XCTAssertTrue(routes.contains(Route(method: .GET, path: path) { _ in Response() }!))

        XCTAssertEqual(builder.routes.count, 2)
        XCTAssertEqual(builder.routes[.DELETE].count, 1)
        XCTAssertEqual(builder.routes[.GET].count, 1)
        XCTAssertTrue(builder.routes.has(Route(method: .DELETE, path: path) { _ in Response() }!))
        XCTAssertTrue(builder.routes.has(Route(method: .GET, path: path) { _ in Response() }!))
    }

    func testRequestDefaultMethods() {
        // Arrange
        let path = "/posts/{id<\\d+>}"

        // Act
        let routes = builder.request(path) { _ in Response() }

        // Assert
        XCTAssertEqual(routes.count, 7)
        XCTAssertTrue(routes.contains(Route(method: .DELETE, path: path) { _ in Response() }!))
        XCTAssertTrue(routes.contains(Route(method: .GET, path: path) { _ in Response() }!))
        XCTAssertTrue(routes.contains(Route(method: .HEAD, path: path) { _ in Response() }!))
        XCTAssertTrue(routes.contains(Route(method: .OPTIONS, path: path) { _ in Response() }!))
        XCTAssertTrue(routes.contains(Route(method: .PATCH, path: path) { _ in Response() }!))
        XCTAssertTrue(routes.contains(Route(method: .POST, path: path) { _ in Response() }!))
        XCTAssertTrue(routes.contains(Route(method: .PUT, path: path) { _ in Response() }!))

        XCTAssertEqual(builder.routes.count, 7)
        XCTAssertEqual(builder.routes[.DELETE].count, 1)
        XCTAssertEqual(builder.routes[.GET].count, 1)
        XCTAssertEqual(builder.routes[.HEAD].count, 1)
        XCTAssertEqual(builder.routes[.OPTIONS].count, 1)
        XCTAssertEqual(builder.routes[.PATCH].count, 1)
        XCTAssertEqual(builder.routes[.POST].count, 1)
        XCTAssertEqual(builder.routes[.PUT].count, 1)
        XCTAssertTrue(builder.routes.has(Route(method: .DELETE, path: path) { _ in Response() }!))
        XCTAssertTrue(builder.routes.has(Route(method: .GET, path: path) { _ in Response() }!))
        XCTAssertTrue(builder.routes.has(Route(method: .HEAD, path: path) { _ in Response() }!))
        XCTAssertTrue(builder.routes.has(Route(method: .OPTIONS, path: path) { _ in Response() }!))
        XCTAssertTrue(builder.routes.has(Route(method: .PATCH, path: path) { _ in Response() }!))
        XCTAssertTrue(builder.routes.has(Route(method: .POST, path: path) { _ in Response() }!))
        XCTAssertTrue(builder.routes.has(Route(method: .PUT, path: path) { _ in Response() }!))
    }

    func testGroup() {
        // Act
        builder.group(name: "front_") { front in
            front.group(name: "blog_") { blog in
                blog.get(name: "index") { _ in Response() }
            }
            front.group("/categories", name: "category_") { categories in
                categories.get("/{name}", name: "get") { _ in Response() }
                categories.get(name: "list") { _ in Response() }
            }
            front.group("/posts", name: "post_") { posts in
                posts.get(name: "list") { _ in Response() }
            }
            front.group("/tags", name: "tag_") { tags in
                tags.get("/{name}", name: "get") { _ in Response() }
                tags.get(name: "list") { _ in Response() }
            }
        }
        builder.group("/admin", name: "admin_") { admin in
            admin.group("/categories", name: "category_") { categories in
                categories.post(name: "create") { _ in Response() }
                categories.get(name: "list") { _ in Response() }
                categories.group("/{id<\\d+>}") { category in
                    category.delete(name: "delete") { _ in Response() }
                    category.get(name: "get") { _ in Response() }
                    category.put(name: "update") { _ in Response() }
                }
            }
            admin.group("/posts", name: "post_") { posts in
                posts.post(name: "create") { _ in Response() }
                posts.get(name: "list") { _ in Response() }
                posts.group("/{id<\\d+>}") { post in
                    post.delete(name: "delete") { _ in Response() }
                    post.get(name: "get") { _ in Response() }
                    post.put(name: "update") { _ in Response() }
                }
            }
            admin.group("/tags", name: "tag_") { tags in
                tags.post(name: "create") { _ in Response() }
                tags.get(name: "list") { _ in Response() }
                tags.group("/{id<\\d+>}") { tag in
                    tag.delete(name: "delete") { _ in Response() }
                    tag.get(name: "get") { _ in Response() }
                    tag.put(name: "update") { _ in Response() }
                }
            }
        }

        // Assert
        XCTAssertEqual(builder.routes.count, 4)

        XCTAssertEqual(builder.routes[.GET].count, 12)
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/" && $0.name == "front_blog_index"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/categories/{name}" && $0.name == "front_category_get"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/categories" && $0.name == "front_category_list"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/posts" && $0.name == "front_post_list"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/tags/{name}" && $0.name == "front_tag_get"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/tags" && $0.name == "front_tag_list"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/admin/categories/{id<\\d+>}" && $0.name == "admin_category_get"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/admin/categories" && $0.name == "admin_category_list"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/admin/posts/{id<\\d+>}" && $0.name == "admin_post_get"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/admin/posts" && $0.name == "admin_post_list"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/admin/tags/{id<\\d+>}" && $0.name == "admin_tag_get"
        }))
        XCTAssertTrue(builder.routes[.GET].contains(where: {
            $0.path == "/admin/tags" && $0.name == "admin_tag_list"
        }))

        XCTAssertEqual(builder.routes[.POST].count, 3)
        XCTAssertTrue(builder.routes[.POST].contains(where: {
            $0.path == "/admin/categories" && $0.name == "admin_category_create"
        }))
        XCTAssertTrue(builder.routes[.POST].contains(where: {
            $0.path == "/admin/posts" && $0.name == "admin_post_create"
        }))
        XCTAssertTrue(builder.routes[.POST].contains(where: {
            $0.path == "/admin/tags" && $0.name == "admin_tag_create"
        }))

        XCTAssertEqual(builder.routes[.PUT].count, 3)
        XCTAssertTrue(builder.routes[.PUT].contains(where: {
            $0.path == "/admin/categories/{id<\\d+>}" && $0.name == "admin_category_update"
        }))
        XCTAssertTrue(builder.routes[.PUT].contains(where: {
            $0.path == "/admin/posts/{id<\\d+>}" && $0.name == "admin_post_update"
        }))
        XCTAssertTrue(builder.routes[.PUT].contains(where: {
            $0.path == "/admin/tags/{id<\\d+>}" && $0.name == "admin_tag_update"
        }))

        XCTAssertEqual(builder.routes[.DELETE].count, 3)
        XCTAssertTrue(builder.routes[.DELETE].contains(where: {
            $0.path == "/admin/categories/{id<\\d+>}" && $0.name == "admin_category_delete"
        }))
        XCTAssertTrue(builder.routes[.DELETE].contains(where: {
            $0.path == "/admin/posts/{id<\\d+>}" && $0.name == "admin_post_delete"
        }))
        XCTAssertTrue(builder.routes[.DELETE].contains(where: {
            $0.path == "/admin/tags/{id<\\d+>}" && $0.name == "admin_tag_delete"
        }))
    }

    func testGroupedWithInvalidPath() {
        // Act
        let group = builder.grouped("", name: "front_")

        // Assert
        XCTAssertNil(group)
    }
}
