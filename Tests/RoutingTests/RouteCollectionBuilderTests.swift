import XCTest
import struct HTTP.Response
@testable import Routing

final class RouteCollectionBuilderTests: XCTestCase {
    var builder: RouteCollectionBuilder!

    override func setUp() {
        super.setUp()

        // Arrange
        builder = RouteCollectionBuilder()
    }

    func testDelete() {
        // Act
        let route = builder.delete("/posts/{id<\\d+>}", name: "post_delete") { request in Response() }

        // Assert
        XCTAssertEqual(builder.routes.count, 1)
        XCTAssertEqual(builder.routes[.DELETE].count, 1)
        XCTAssertTrue(builder.routes[.DELETE].contains(where: { $0.path == route?.path && $0.name == route?.name }))
    }

    func testGet() {
        // Act
        let route = builder.get("/posts/{id<\\d+>}", name: "post_get") { request in Response() }

        // Assert
        XCTAssertEqual(builder.routes.count, 1)
        XCTAssertEqual(builder.routes[.GET].count, 1)
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == route?.path && $0.name == route?.name }))
    }

    func testGroupRoutes() {
        // Act
        builder.group(name: "front_") { front in
            front.group(name: "blog_") { blog in
                blog.get(name: "index") { request in Response() }
            }
            front.group("/categories", name: "category_") { categories in
                categories.get("/{name}", name: "get") { request in Response() }
                categories.get(name: "list") { request in Response() }
            }
            front.group("/posts", name: "post_") { posts in
                posts.get(name: "list") { request in Response() }
            }
            front.group("/tags", name: "tag_") { tags in
                tags.get("/{name}", name: "get") { request in Response() }
                tags.get(name: "list") { request in Response() }
            }
        }
        builder.group("/admin", name: "admin_") { admin in
            admin.group("/categories", name: "category_") { categories in
                categories.post(name: "create") { request in Response() }
                categories.delete("/{id<\\d+>}", name: "delete") { request in Response() }
                categories.get("/{id<\\d+>}", name: "get") { request in Response() }
                categories.get(name: "list") { request in Response() }
                categories.put("/{id<\\d+>}", name: "update") { request in Response() }
            }
            admin.group("/posts", name: "post_") { posts in
                posts.post(name: "create") { request in Response() }
                posts.delete("/{id<\\d+>}", name: "delete") { request in Response() }
                posts.get("/{id<\\d+>}", name: "get") { request in Response() }
                posts.get(name: "list") { request in Response() }
                posts.put("/{id<\\d+>}", name: "update") { request in Response() }
            }
            admin.group("/tags", name: "tag_") { tags in
                tags.post(name: "create") { request in Response() }
                tags.delete("/{id<\\d+>}", name: "delete") { request in Response() }
                tags.get("/{id<\\d+>}", name: "get") { request in Response() }
                tags.get(name: "list") { request in Response() }
                tags.put("/{id<\\d+>}", name: "update") { request in Response() }
            }
        }

        // Assert
        XCTAssertEqual(builder.routes.count, 4)

        XCTAssertEqual(builder.routes[.GET].count, 12)
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/" && $0.name == "front_blog_index" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/categories/{name}" && $0.name == "front_category_get" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/categories" && $0.name == "front_category_list" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/posts" && $0.name == "front_post_list" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/tags/{name}" && $0.name == "front_tag_get" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/tags" && $0.name == "front_tag_list" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/admin/categories/{id<\\d+>}" && $0.name == "admin_category_get" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/admin/categories" && $0.name == "admin_category_list" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/admin/posts/{id<\\d+>}" && $0.name == "admin_post_get" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/admin/posts" && $0.name == "admin_post_list" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/admin/tags/{id<\\d+>}" && $0.name == "admin_tag_get" }))
        XCTAssertTrue(builder.routes[.GET].contains(where: { $0.path == "/admin/tags" && $0.name == "admin_tag_list" }))

        XCTAssertEqual(builder.routes[.POST].count, 3)
        XCTAssertTrue(builder.routes[.POST].contains(where: { $0.path == "/admin/categories" && $0.name == "admin_category_create" }))
        XCTAssertTrue(builder.routes[.POST].contains(where: { $0.path == "/admin/posts" && $0.name == "admin_post_create" }))
        XCTAssertTrue(builder.routes[.POST].contains(where: { $0.path == "/admin/tags" && $0.name == "admin_tag_create" }))

        XCTAssertEqual(builder.routes[.PUT].count, 3)
        XCTAssertTrue(builder.routes[.PUT].contains(where: { $0.path == "/admin/categories/{id<\\d+>}" && $0.name == "admin_category_update" }))
        XCTAssertTrue(builder.routes[.PUT].contains(where: { $0.path == "/admin/posts/{id<\\d+>}" && $0.name == "admin_post_update" }))
        XCTAssertTrue(builder.routes[.PUT].contains(where: { $0.path == "/admin/tags/{id<\\d+>}" && $0.name == "admin_tag_update" }))

        XCTAssertEqual(builder.routes[.DELETE].count, 3)
        XCTAssertTrue(builder.routes[.DELETE].contains(where: { $0.path == "/admin/categories/{id<\\d+>}" && $0.name == "admin_category_delete" }))
        XCTAssertTrue(builder.routes[.DELETE].contains(where: { $0.path == "/admin/posts/{id<\\d+>}" && $0.name == "admin_post_delete" }))
        XCTAssertTrue(builder.routes[.DELETE].contains(where: { $0.path == "/admin/tags/{id<\\d+>}" && $0.name == "admin_tag_delete" }))
    }
}
