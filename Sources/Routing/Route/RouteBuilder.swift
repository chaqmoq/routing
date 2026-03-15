import HTTP

/// Provides a fluent DSL for registering HTTP routes on an underlying ``Router``.
///
/// `RouteBuilder` is the base class for ``RouteGroup`` and ``TrieRouter``.
/// Call the HTTP-method helpers (`get`, `post`, `put`, …) to create and
/// register routes whose path is prefixed by this builder's own `path`.
///
/// - Note: `router` is a `weak` reference to avoid a retain cycle.  If the
///   owning ``TrieRouter`` is deallocated before route registration is complete,
///   registrations will be silently dropped in release builds and will trigger
///   `assertionFailure` in debug builds.
open class RouteBuilder {
    /// The path prefix that every route registered through this builder inherits.
    let path: String

    /// The name prefix that every route registered through this builder inherits.
    let name: String

    /// The middleware stack prepended to every route registered through this builder.
    let middleware: [Middleware]

    /// Weak reference to the router that persists and resolves routes.
    weak var router: Router?

    init(
        name: String = "",
        middleware: [Middleware] = .init()
    ) {
        path = Route.defaultPath
        self.name = name
        self.middleware = middleware
    }

    init?(
        path: String,
        name: String = "",
        middleware: [Middleware] = .init()
    ) {
        let (isValid, _) = Route.isValid(path: path)

        if isValid {
            self.path = path
            self.name = name
            self.middleware = middleware
        } else {
            return nil
        }
    }

    @discardableResult
    public func delete(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(
            path,
            methods: [.DELETE],
            name: name,
            middleware: middleware,
            handler: handler
        ).first
    }

    @discardableResult
    public func get(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(
            path,
            methods: [.GET],
            name: name,
            middleware: middleware,
            handler: handler
        ).first
    }

    @discardableResult
    public func head(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(
            path,
            methods: [.HEAD],
            name: name,
            middleware: middleware,
            handler: handler
        ).first
    }

    @discardableResult
    public func options(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(
            path,
            methods: [.OPTIONS],
            name: name,
            middleware: middleware,
            handler: handler
        ).first
    }

    @discardableResult
    public func patch(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(
            path,
            methods: [.PATCH],
            name: name,
            middleware: middleware,
            handler: handler
        ).first
    }

    @discardableResult
    public func post(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(
            path,
            methods: [.POST],
            name: name,
            middleware: middleware,
            handler: handler
        ).first
    }

    @discardableResult
    public func put(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> Route? {
        _request(
            path,
            methods: [.PUT],
            name: name,
            middleware: middleware,
            handler: handler
        ).first
    }

    @discardableResult
    public func request(
        _ path: String = Route.defaultPath,
        methods: Set<Request.Method> = Set(Request.Method.allCases),
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> [Route] {
        _request(
            path,
            methods: methods,
            middleware: middleware,
            handler: handler
        )
    }

    @discardableResult
    func _request(
        _ path: String = Route.defaultPath,
        methods: Set<Request.Method> = Set(Request.Method.allCases),
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> [Route] {
        let (isValid, _) = Route.isValid(path: path)
        var routes = [Route]()

        if isValid {
            for method in methods {
                if let route = Route(
                    method: method,
                    path: self.path.appending(path: path),
                    name: self.name + name,
                    middleware: self.middleware + middleware,
                    handler: handler
                ) {
                    routes.append(route)

                    if let router = router {
                        router.register(route: route)
                    } else {
                        assertionFailure(
                            "Router is nil — ensure the TrieRouter outlives all " +
                            "RouteBuilder/RouteGroup instances that register routes."
                        )
                    }
                }
            }
        }

        return routes
    }
}
