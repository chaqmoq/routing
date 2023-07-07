import HTTP

public class RouteBuilder {
    let path: String
    let name: String
    public var middleware: [Middleware]

    init(path: String = "", name: String = "", middleware: [Middleware] = .init()) {
        self.path = path
        self.name = name
        self.middleware = middleware
    }

    @discardableResult
    public func delete(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(path, methods: [.DELETE], name: name, middleware: middleware, handler: handler).first
    }

    @discardableResult
    public func get(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(path, methods: [.GET], name: name, middleware: middleware, handler: handler).first
    }

    @discardableResult
    public func head(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(path, methods: [.HEAD], name: name, middleware: middleware, handler: handler).first
    }

    @discardableResult
    public func options(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(path, methods: [.OPTIONS], name: name, middleware: middleware, handler: handler).first
    }

    @discardableResult
    public func patch(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(path, methods: [.PATCH], name: name, middleware: middleware, handler: handler).first
    }

    @discardableResult
    public func post(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(path, methods: [.POST], name: name, middleware: middleware, handler: handler).first
    }

    @discardableResult
    public func put(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(path, methods: [.PUT], name: name, middleware: middleware, handler: handler).first
    }

    @discardableResult
    public func request(
        _ path: String = Route.defaultPath,
        methods: Set<Request.Method> = Set(Request.Method.allCases),
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> [Route] {
        _request(path, methods: methods, middleware: middleware, handler: handler)
    }

    @discardableResult
    func _request(
        _ path: String = Route.defaultPath,
        methods: Set<Request.Method> = Set(Request.Method.allCases),
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> [Route] {
        var routes = [Route]()

        for method in methods {
            var path = Route.normalize(path: path)
            let (isValid, _) = Route.isValid(path: path)

            if isValid {
                if !self.path.isEmpty {
                    path = self.path + path
                }

                if let route = Route(
                    method: method,
                    path: path,
                    name: self.name + name,
                    middleware: self.middleware + middleware,
                    handler: handler
                ) {
                    routes.append(route)
                }
            }
        }

        return routes
    }
}
