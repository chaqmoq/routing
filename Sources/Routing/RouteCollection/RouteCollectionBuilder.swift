import struct HTTP.Request

public class RouteCollectionBuilder {
    public var routes: RouteCollection
    private var current: RouteCollection?

    public init(routes: RouteCollection = .init()) {
        self.routes = routes
    }

    @discardableResult
    public func delete(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.DELETE], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func get(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.GET], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func head(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.HEAD], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func options(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.OPTIONS], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func patch(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.PATCH], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func post(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.POST], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func put(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.PUT], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public func request(
        methods: Set<Request.Method>? = nil,
        path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Set<Route> {
        let methods = methods ?? Set(Request.Method.allCases)
        var routes: Set<Route> = []

        for method in methods {
            if let route = Route(method: method, path: path, name: name, requestHandler: handler) {
                if let current = current {
                    if let route = current.insert(route) {
                        self.routes.insert(route)
                        routes.insert(route)
                    }
                } else {
                    self.routes.insert(route)
                    routes.insert(route)
                }
            }
        }

        return routes
    }

    public func group(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping (RouteCollectionBuilder) -> Void
    ) {
        if let current = current {
            self.current = RouteCollection(current, path: path, name: name)
        } else {
            current = RouteCollection(path: path, name: name)
        }

        handler(self)
    }
}
