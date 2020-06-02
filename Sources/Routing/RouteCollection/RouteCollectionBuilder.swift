import struct HTTP.Request

public class RouteCollectionBuilder {
    public var routes: RouteCollection
    private weak var root: RouteCollectionBuilder?

    public init(_ routes: RouteCollection = .init()) {
        self.routes = routes
    }

    @discardableResult
    public func delete(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        makeRequest(methods: [.DELETE], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func get(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        makeRequest(methods: [.GET], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func head(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        makeRequest(methods: [.HEAD], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func options(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        makeRequest(methods: [.OPTIONS], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func patch(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        makeRequest(methods: [.PATCH], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func post(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        makeRequest(methods: [.POST], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func put(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        makeRequest(methods: [.PUT], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func request(
        methods: Set<Request.Method>? = nil,
        path: String = "/",
        handler: @escaping Route.RequestHandler
    ) -> Set<Route> {
        makeRequest(methods: methods, path: path, handler: handler)
    }

    @discardableResult
    private func makeRequest(
        methods: Set<Request.Method>? = nil,
        path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Set<Route> {
        let methods = methods ?? Set(Request.Method.allCases)
        var routes: Set<Route> = []

        for method in methods {
            if let route = Route(method: method, path: path, name: name, requestHandler: handler) {
                if let route = self.routes.insert(route) {
                    if let root = root {
                        if let route = root.routes.insert(route) {
                            routes.insert(route)
                        }
                    } else {
                        routes.insert(route)
                    }
                }
            }
        }

        return routes
    }

    public func grouped(_ path: String = "/", name: String? = nil) -> RouteCollectionBuilder {
        if root == nil { root = self }
        let builder = RouteCollectionBuilder(RouteCollection(routes, path: path, name: name))
        builder.root = root

        return builder
    }

    public func group(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping (RouteCollectionBuilder) -> Void
    ) {
        handler(grouped(path, name: name))
    }
}
