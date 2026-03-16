import HTTP
@testable import Routing
import XCTest

/// Full integration test suite for `TrieRouter`.
///
/// Every test follows the Arrange / Act / Assert pattern and is grouped into
/// clearly labelled sections so that failures pinpoint the affected feature.
final class TrieRouterTests: XCTestCase {

    // MARK: - Setup

    var router: TrieRouter!

    override func setUp() {
        super.setUp()
        router = TrieRouter()
    }

    // MARK: - Helpers

    /// Wraps the URI initialiser so that only this one line needs updating if
    /// the HTTP package ever changes its API.
    private func uri(_ path: String) -> URI { URI(path)! }

    // MARK: - Root route

    func testResolveRootRoute() {
        // Arrange
        router.get { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/"))

        // Assert
        XCTAssertNotNil(route, "Root GET route should resolve")
    }

    func testRootRouteDoesNotMatchNonRootPath() {
        // Arrange
        router.get { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts"))

        // Assert
        XCTAssertNil(route, "Root route should not match a deeper path")
    }

    // MARK: - Constant routes

    func testResolveSingleSegmentConstantRoute() {
        // Arrange
        router.get("/posts") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts"))

        // Assert
        XCTAssertNotNil(route)
    }

    func testResolveNestedConstantRoute() {
        // Arrange
        router.get("/api/v1/posts") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/api/v1/posts"))

        // Assert
        XCTAssertNotNil(route)
    }

    func testUnregisteredConstantRouteReturnsNil() {
        // Arrange
        router.get("/posts") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/comments"))

        // Assert
        XCTAssertNil(route, "Unregistered path should return nil")
    }

    func testWrongMethodReturnsNil() {
        // Arrange
        router.get("/posts") { _ in Response() }

        // Act
        let route = router.resolve(method: .POST, uri: uri("/posts"))

        // Assert
        XCTAssertNil(route, "Wrong HTTP method should return nil")
    }

    // MARK: - Parameterised routes (no constraint)

    func testResolveRouteWithSingleParameter() {
        // Arrange
        router.get("/posts/{id}") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts/42"))

        // Assert
        XCTAssertNotNil(route)
        let value: String? = route?[parameter: "id"]
        XCTAssertEqual(value, "42")
    }

    func testResolveRouteWithMultipleParameters() {
        // Arrange
        router.get("/users/{userId}/posts/{postId}") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/users/7/posts/99"))

        // Assert
        XCTAssertNotNil(route)
        let userId: String? = route?[parameter: "userId"]
        let postId: String? = route?[parameter: "postId"]
        XCTAssertEqual(userId, "7")
        XCTAssertEqual(postId, "99")
    }

    // MARK: - Parameters with requirements

    func testResolveRouteWithRequirementMatchingValue() {
        // Arrange
        router.get("/posts/{id<\\d+>}") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts/123"))

        // Assert
        XCTAssertNotNil(route, "Numeric id should match \\d+ requirement")
        let value: Int? = route?[parameter: "id"]
        XCTAssertEqual(value, 123)
    }

    func testResolveRouteWithRequirementNotMatchingValue() {
        // Arrange
        router.get("/posts/{id<\\d+>}") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts/abc"))

        // Assert
        XCTAssertNil(route, "Non-numeric segment should not match \\d+ requirement")
    }

    func testRequirementWithAlphanumericPattern() {
        // Arrange
        router.get("/users/{slug<[a-z0-9-]+>}") { _ in Response() }

        // Act
        let matching = router.resolve(method: .GET, uri: uri("/users/john-doe"))
        let nonMatching = router.resolve(method: .GET, uri: uri("/users/John_Doe"))

        // Assert
        XCTAssertNotNil(matching)
        XCTAssertNil(nonMatching)
    }

    // MARK: - Optional default values

    func testResolveRouteWithOptionalParamWhenValueProvided() {
        // Arrange
        router.get("/posts/{page?1}") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts/3"))

        // Assert
        XCTAssertNotNil(route)
        let page: Int? = route?[parameter: "page"]
        XCTAssertEqual(page, 3, "Provided value should override the default")
    }

    func testResolveRouteWithOptionalParamWhenValueOmitted() {
        // Arrange
        router.get("/posts/{page?1}") { _ in Response() }

        // Act — request the parent path without the optional segment
        let route = router.resolve(method: .GET, uri: uri("/posts"))

        // Assert
        XCTAssertNotNil(route, "Omitting an optional param should fall back to the default-value route")
    }

    func testResolveRouteWithRequirementAndOptionalDefault() {
        // Arrange
        router.get("/posts/{id<\\d+>?1}") { _ in Response() }

        // Act
        let withValue = router.resolve(method: .GET, uri: uri("/posts/42"))
        let withDefault = router.resolve(method: .GET, uri: uri("/posts"))

        // Assert
        XCTAssertNotNil(withValue)
        XCTAssertNotNil(withDefault)
        let id: Int? = withValue?[parameter: "id"]
        XCTAssertEqual(id, 42)
    }

    // MARK: - Forced default values

    func testResolveRouteWithForcedDefault() {
        // Arrange
        router.get("/posts/{id!1}") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts/5"))

        // Assert
        XCTAssertNotNil(route)
        let id: Int? = route?[parameter: "id"]
        XCTAssertEqual(id, 5)
    }

    // MARK: - Mixed constant + parameterised segments

    func testConstantPrecedesVariableWithSameName() {
        // Arrange – register both; constant "latest" should win over a variable.
        router.get("/posts/latest") { _ in Response() }
        router.get("/posts/{id<\\d+>}") { _ in Response() }

        // Act
        let constantRoute = router.resolve(method: .GET, uri: uri("/posts/latest"))
        let variableRoute = router.resolve(method: .GET, uri: uri("/posts/99"))

        // Assert
        XCTAssertNotNil(constantRoute)
        XCTAssertNotNil(variableRoute)
        XCTAssertEqual(constantRoute?.path, "/posts/latest")
        XCTAssertEqual(variableRoute?.path, "/posts/{id<\\d+>}")
    }

    // MARK: - HTTP methods

    func testMultipleMethodsOnSamePath() {
        // Arrange
        router.get("/posts") { _ in Response() }
        router.post("/posts") { _ in Response() }

        // Act
        let getRoute = router.resolve(method: .GET, uri: uri("/posts"))
        let postRoute = router.resolve(method: .POST, uri: uri("/posts"))
        let putRoute = router.resolve(method: .PUT, uri: uri("/posts"))

        // Assert
        XCTAssertNotNil(getRoute)
        XCTAssertNotNil(postRoute)
        XCTAssertNil(putRoute, "PUT is not registered and should return nil")
    }

    func testAllStandardMethodsCanBeRegistered() {
        // Arrange
        router.delete("/r") { _ in Response() }
        router.get("/r") { _ in Response() }
        router.head("/r") { _ in Response() }
        router.options("/r") { _ in Response() }
        router.patch("/r") { _ in Response() }
        router.post("/r") { _ in Response() }
        router.put("/r") { _ in Response() }

        // Act / Assert
        for method in [Request.Method.DELETE, .GET, .HEAD, .OPTIONS, .PATCH, .POST, .PUT] {
            XCTAssertNotNil(
                router.resolve(method: method, uri: uri("/r")),
                "\(method.rawValue) should be resolved"
            )
        }
    }

    // MARK: - Route groups

    func testRouteGroupInheritsPrefix() {
        // Arrange
        router.group("/api") { group in
            group.get("/posts") { _ in Response() }
        }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/api/posts"))

        // Assert
        XCTAssertNotNil(route)
        XCTAssertEqual(route?.path, "/api/posts")
    }

    func testNestedRouteGroups() {
        // Arrange
        router.group("/api") { api in
            api.group("/v1") { v1 in
                v1.get("/posts") { _ in Response() }
            }
        }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/api/v1/posts"))

        // Assert
        XCTAssertNotNil(route)
        XCTAssertEqual(route?.path, "/api/v1/posts")
    }

    func testRouteGroupDoesNotLeakOutsidePrefix() {
        // Arrange
        router.group("/api") { group in
            group.get("/posts") { _ in Response() }
        }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts"))

        // Assert
        XCTAssertNil(route, "Group prefix should not be stripped on resolution")
    }

    // MARK: - Name propagation through groups

    func testRouteGroupPropagatesName() {
        // Arrange
        router.group("/posts", name: "posts.") { group in
            group.get(name: "index") { _ in Response() }
        }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts"))

        // Assert
        XCTAssertEqual(route?.name, "posts.index")
    }

    // MARK: - Parameter type conversion via subscript

    func testParameterSubscriptReturnsInt() {
        // Arrange
        router.get("/items/{count<\\d+>}") { _ in Response() }
        let route = router.resolve(method: .GET, uri: uri("/items/42"))!

        // Act / Assert
        XCTAssertEqual(route[parameter: "count"] as Int?, 42)
    }

    func testParameterSubscriptReturnsString() {
        // Arrange
        router.get("/items/{label}") { _ in Response() }
        let route = router.resolve(method: .GET, uri: uri("/items/hello"))!

        // Act / Assert
        XCTAssertEqual(route[parameter: "label"] as String?, "hello")
    }

    func testParameterSubscriptReturnsNilForUnknownName() {
        // Arrange
        router.get("/items/{id}") { _ in Response() }
        let route = router.resolve(method: .GET, uri: uri("/items/1"))!

        // Act / Assert
        let value: String? = route[parameter: "nonexistent"]
        XCTAssertNil(value)
    }

    // MARK: - Edge cases

    func testResolvingEmptyURIReturnsNil() {
        // Arrange
        router.get("/posts") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: URI("")!)

        // Assert
        XCTAssertNil(route)
    }

    func testRegisteringTwoRoutesWithSameVariableSegmentDoesNotDuplicate() {
        // Arrange – both routes share the parameterised segment /posts/{id}.
        router.get("/posts/{id<\\d+>}") { _ in Response() }
        router.delete("/posts/{id<\\d+>}") { _ in Response() }

        // Act
        let getRoute = router.resolve(method: .GET, uri: uri("/posts/1"))
        let deleteRoute = router.resolve(method: .DELETE, uri: uri("/posts/1"))

        // Assert – each method resolves independently.
        XCTAssertNotNil(getRoute)
        XCTAssertNotNil(deleteRoute)
    }

    func testRequirementWithInnerCaptureGroupExtractsCorrectly() {
        // Regression: before the named-group fix, a requirement that itself
        // contained a capture group would shift subsequent parameter indices,
        // causing the wrong value to be bound to the second parameter.
        router.get("/filter/{kind<(asc|desc)>}/{id<\\d+>}") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/filter/asc/7"))

        // Assert
        XCTAssertNotNil(route)
        XCTAssertEqual(route?[parameter: "kind"] as String?, "asc",
                       "'kind' must not be displaced by the inner capture group")
        XCTAssertEqual(route?[parameter: "id"] as Int?, 7)
    }

    // MARK: - Thread safety

    func testConcurrentResolvesDoNotCrash() {
        // Arrange – register several routes up front.
        router.get("/posts") { _ in Response() }
        router.get("/posts/{id<\\d+>}") { _ in Response() }
        router.get("/users/{name}") { _ in Response() }

        // Act – fire many concurrent resolves.  With TSAN enabled a data race
        // would be detected immediately; without TSAN a crash is still likely.
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        let group = DispatchGroup()

        for _ in 0 ..< 200 {
            group.enter()
            queue.async {
                _ = self.router.resolve(method: .GET, uri: self.uri("/posts"))
                _ = self.router.resolve(method: .GET, uri: self.uri("/posts/42"))
                _ = self.router.resolve(method: .GET, uri: self.uri("/users/alice"))
                group.leave()
            }
        }

        group.wait()
        // Reaching here without crashing is the pass condition.
    }

    func testConcurrentRegistrationAndResolutionDoNotCrash() {
        // Act – interleave writes (register) and reads (resolve).
        let queue = DispatchQueue(label: "test.rw", attributes: .concurrent)
        let group = DispatchGroup()

        for i in 0 ..< 50 {
            group.enter()
            queue.async(flags: .barrier) {
                self.router.get("/resource/\(i)") { _ in Response() }
                group.leave()
            }

            group.enter()
            queue.async {
                _ = self.router.resolve(method: .GET, uri: self.uri("/resource/\(i)"))
                group.leave()
            }
        }

        group.wait()
    }

    // MARK: - Wildcard (*)

    func testWildcardMatchesAnySegment() {
        // Arrange
        router.get("/posts/*/comments") { _ in Response() }

        // Act
        let matchesNumber = router.resolve(method: .GET, uri: uri("/posts/42/comments"))
        let matchesWord = router.resolve(method: .GET, uri: uri("/posts/anything/comments"))
        let noMatch = router.resolve(method: .GET, uri: uri("/posts/42/other"))

        // Assert
        XCTAssertNotNil(matchesNumber)
        XCTAssertNotNil(matchesWord)
        XCTAssertNil(noMatch)
    }

    func testWildcardDoesNotCaptureValue() {
        // Arrange
        router.get("/posts/*/comments") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts/42/comments"))

        // Assert
        XCTAssertNotNil(route)
        let v: String? = route?[parameter: "nonexistent"]
        XCTAssertNil(v)
    }

    func testConstantPrecedesWildcard() {
        // Arrange
        router.get("/posts/latest/comments") { _ in Response() }
        router.get("/posts/*/comments") { _ in Response() }

        // Act
        let constant = router.resolve(method: .GET, uri: uri("/posts/latest/comments"))
        let wildcard = router.resolve(method: .GET, uri: uri("/posts/42/comments"))

        // Assert
        XCTAssertEqual(constant?.path, "/posts/latest/comments")
        XCTAssertEqual(wildcard?.path, "/posts/*/comments")
    }

    // MARK: - Catchall (**)

    func testCatchallMatchesMultipleSegments() {
        // Arrange
        router.get("/static/**") { _ in Response() }

        // Act
        let singleLevel = router.resolve(method: .GET, uri: uri("/static/css/main.css"))
        let singleSegment = router.resolve(method: .GET, uri: uri("/static/a"))
        let multiLevel = router.resolve(method: .GET, uri: uri("/static/a/b/c/d"))

        // Assert
        XCTAssertNotNil(singleLevel)
        XCTAssertNotNil(singleSegment)
        XCTAssertNotNil(multiLevel)
    }

    func testCatchallCapturesRemainingSegments() {
        // Arrange
        router.get("/static/**") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/static/css/main.css"))

        // Assert
        XCTAssertEqual(route?.catchall, ["css", "main.css"])
    }

    func testCatchallSingleSegment() {
        // Arrange
        router.get("/files/**") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/files/readme.txt"))

        // Assert
        XCTAssertEqual(route?.catchall, ["readme.txt"])
    }

    func testCatchallDoesNotMatchParentPath() {
        // Arrange
        router.get("/static/**") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/static"))

        // Assert
        XCTAssertNil(route)
    }

    // MARK: - RouteParameterConvertible

    struct PostID: RouteParameterConvertible {
        let rawValue: Int
        static func convert(from string: String) -> PostID? {
            Int(string).map(PostID.init(rawValue:))
        }
    }

    func testCustomTypeConvertible() {
        // Arrange
        router.get("/posts/{id<\\d+>}") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/posts/7"))!
        let id: PostID? = route[parameter: "id"]

        // Assert
        XCTAssertEqual(id?.rawValue, 7)
    }

    func testBuiltInTypesViaConvertible() {
        // Arrange
        router.get("/items/{n<\\d+>}") { _ in Response() }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/items/99"))!
        let intVal: Int? = route[parameter: "n"]
        let uintVal: UInt? = route[parameter: "n"]
        let doubleVal: Double? = route[parameter: "n"]
        let stringVal: String? = route[parameter: "n"]

        // Assert
        XCTAssertEqual(intVal, 99)
        XCTAssertEqual(uintVal, 99)
        XCTAssertEqual(doubleVal, 99.0)
        XCTAssertEqual(stringVal, "99")
    }

    // MARK: - Middleware-only grouping

    func testMiddlewareOnlyGroupDoesNotChangePrefix() {
        // Arrange
        struct MarkerMiddleware: Middleware {
            let tag: String
            func respond(to request: Request, chainingTo next: Responder) async throws -> any Encodable {
                try await next(request)
            }
        }

        router.group(middleware: [MarkerMiddleware(tag: "auth")]) { group in
            group.get("/profile") { _ in Response() }
        }

        // Act
        let route = router.resolve(method: .GET, uri: uri("/profile"))

        // Assert
        XCTAssertNotNil(route)
        XCTAssertEqual(route?.path, "/profile")
        XCTAssertEqual(route?.middleware.count, 1)
    }

    // MARK: - TrieRouter

    func testFrozenRouterResolvesRoutes() {
        // Arrange
        router.get("/posts", name: "posts.index") { _ in Response() }
        router.get("/posts/{id<\\d+>}", name: "posts.show") { _ in Response() }

        // Act
        let frozen = router.build()
        let indexRoute = frozen.resolve(method: .GET, uri: uri("/posts"))
        let showRoute = frozen.resolve(method: .GET, uri: uri("/posts/5"))
        let noMatch = frozen.resolve(method: .POST, uri: uri("/posts"))

        // Assert
        XCTAssertNotNil(indexRoute)
        XCTAssertNotNil(showRoute)
        XCTAssertNil(noMatch)
    }

    func testFrozenRouterConcurrentResolvesDoNotCrash() {
        // Arrange
        router.get("/posts/{id<\\d+>}") { _ in Response() }
        let frozen = router.build()

        // Act
        let q = DispatchQueue(label: "frozen.test", attributes: .concurrent)
        let g = DispatchGroup()

        for _ in 0 ..< 200 {
            g.enter()
            q.async {
                _ = frozen.resolve(method: .GET, uri: self.uri("/posts/1"))
                g.leave()
            }
        }

        g.wait()
        // Reaching here without crashing is the pass condition.
    }

    // MARK: - URL generation

    func testURLGenerationSimplePath() {
        // Arrange
        router.get("/posts", name: "posts.index") { _ in Response() }

        // Act
        let url = router.url(for: "posts.index")

        // Assert
        XCTAssertEqual(url, "/posts")
    }

    func testURLGenerationWithParameter() {
        // Arrange
        router.get("/posts/{id<\\d+>}", name: "posts.show") { _ in Response() }

        // Act
        let url = router.url(for: "posts.show", parameters: ["id": "42"])

        // Assert
        XCTAssertEqual(url, "/posts/42")
    }

    func testURLGenerationWithMultipleParameters() {
        // Arrange
        router.get("/users/{userId}/posts/{postId}", name: "user.post") { _ in Response() }

        // Act
        let url = router.url(for: "user.post", parameters: ["userId": "3", "postId": "9"])

        // Assert
        XCTAssertEqual(url, "/users/3/posts/9")
    }

    func testURLGenerationMissingRequiredParameterReturnsNil() {
        // Arrange
        router.get("/posts/{id}", name: "posts.show") { _ in Response() }

        // Act
        let url = router.url(for: "posts.show", parameters: [:])

        // Assert
        XCTAssertNil(url)
    }

    func testURLGenerationUnknownNameReturnsNil() {
        // Arrange / Act
        let url = router.url(for: "nonexistent")

        // Assert
        XCTAssertNil(url)
    }

    func testURLGenerationRequirementValidation() {
        // Arrange
        router.get("/posts/{id<\\d+>}", name: "posts.show") { _ in Response() }

        // Act
        let invalidUrl = router.url(for: "posts.show", parameters: ["id": "abc"])
        let validUrl = router.url(for: "posts.show", parameters: ["id": "5"])

        // Assert
        XCTAssertNil(invalidUrl)
        XCTAssertEqual(validUrl, "/posts/5")
    }

    func testFrozenRouterURLGeneration() {
        // Arrange
        router.get("/posts/{id<\\d+>}", name: "posts.show") { _ in Response() }
        let frozen = router.build()

        // Act
        let url = frozen.url(for: "posts.show", parameters: ["id": "7"])

        // Assert
        XCTAssertEqual(url, "/posts/7")
    }
}
