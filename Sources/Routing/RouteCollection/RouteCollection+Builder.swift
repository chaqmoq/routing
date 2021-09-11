import HTTP

extension RouteCollection {
    /// Helps to build a **tree** of `RouteCollection`s with `Route`s.
    open class Builder {
        /// An instance of `RouteCollection`.
        public var routes: RouteCollection

        private weak var root: Builder?

        /// Initializes a new instance with another `RouteCollection`.
        ///
        /// - Parameter routes: An instance of `RouteCollection`.
        public init(_ routes: RouteCollection = .init()) {
            self.routes = routes
        }

        /// Creates a new instance of `Route` with the `DELETE` HTTP request method.
        ///
        /// - Parameters:
        ///   - path: A path to a resource. Defaults to `Route.defaultPath`.
        ///   - name: A unique name for `Route`. Defaults to an empty string.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        ///   - handler: A handler to call.
        /// - Returns: A new instance of `Route`.
        @discardableResult
        public func delete(
            _ path: String = Route.defaultPath,
            name: String = "",
            middleware: [Middleware] = .init(),
            handler: @escaping Route.Handler
        ) -> Route? {
            _request(path, methods: [.DELETE], name: name, middleware: middleware, handler: handler).first
        }

        /// Creates a new instance of `Route` with the `GET` HTTP request method.
        ///
        /// - Parameters:
        ///   - path: A path to a resource. Defaults to `Route.defaultPath`.
        ///   - name: A unique name for `Route`. Defaults to an empty string.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        ///   - handler: A handler to call.
        /// - Returns: A new instance of `Route`.
        @discardableResult
        public func get(
            _ path: String = Route.defaultPath,
            name: String = "",
            middleware: [Middleware] = .init(),
            handler: @escaping Route.Handler
        ) -> Route? {
            _request(path, methods: [.GET], name: name, middleware: middleware, handler: handler).first
        }

        /// Creates a new instance of `Route` with the `HEAD` HTTP request method.
        ///
        /// - Parameters:
        ///   - path: A path to a resource. Defaults to `Route.defaultPath`.
        ///   - name: A unique name for `Route`. Defaults to an empty string.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        ///   - handler: A handler to call.
        /// - Returns: A new instance of `Route`.
        @discardableResult
        public func head(
            _ path: String = Route.defaultPath,
            name: String = "",
            middleware: [Middleware] = .init(),
            handler: @escaping Route.Handler
        ) -> Route? {
            _request(path, methods: [.HEAD], name: name, middleware: middleware, handler: handler).first
        }

        /// Creates a new instance of `Route` with the `OPTIONS` HTTP request method.
        ///
        /// - Parameters:
        ///   - path: A path to a resource. Defaults to `Route.defaultPath`.
        ///   - name: A unique name for `Route`. Defaults to an empty string.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        ///   - handler: A handler to call.
        /// - Returns: A new instance of `Route`.
        @discardableResult
        public func options(
            _ path: String = Route.defaultPath,
            name: String = "",
            middleware: [Middleware] = .init(),
            handler: @escaping Route.Handler
        ) -> Route? {
            _request(path, methods: [.OPTIONS], name: name, middleware: middleware, handler: handler).first
        }

        /// Creates a new instance of `Route` with the `PATCH` HTTP request method.
        ///
        /// - Parameters:
        ///   - path: A path to a resource. Defaults to `Route.defaultPath`.
        ///   - name: A unique name for `Route`. Defaults to an empty string.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        ///   - handler: A handler to call.
        /// - Returns: A new instance of `Route`.
        @discardableResult
        public func patch(
            _ path: String = Route.defaultPath,
            name: String = "",
            middleware: [Middleware] = .init(),
            handler: @escaping Route.Handler
        ) -> Route? {
            _request(path, methods: [.PATCH], name: name, middleware: middleware, handler: handler).first
        }

        /// Creates a new instance of `Route` with the `POST` HTTP request method.
        ///
        /// - Parameters:
        ///   - path: A path to a resource. Defaults to `Route.defaultPath`.
        ///   - name: A unique name for `Route`. Defaults to an empty string.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        ///   - handler: A handler to call.
        /// - Returns: A new instance of `Route`.
        @discardableResult
        public func post(
            _ path: String = Route.defaultPath,
            name: String = "",
            middleware: [Middleware] = .init(),
            handler: @escaping Route.Handler
        ) -> Route? {
            _request(path, methods: [.POST], name: name, middleware: middleware, handler: handler).first
        }

        /// Creates a new instance of `Route` with the `PUT` HTTP request method.
        ///
        /// - Parameters:
        ///   - path: A path to a resource. Defaults to `Route.defaultPath`.
        ///   - name: A unique name for `Route`. Defaults to an empty string.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        ///   - handler: A handler to call.
        /// - Returns: A new instance of `Route`.
        @discardableResult
        public func put(
            _ path: String = Route.defaultPath,
            name: String = "",
            middleware: [Middleware] = .init(),
            handler: @escaping Route.Handler
        ) -> Route? {
            _request(path, methods: [.PUT], name: name, middleware: middleware, handler: handler).first
        }

        /// Creates an array with one or more instances of `Route` based on HTTP request methods provided.
        ///
        /// - Parameters:
        ///   - path: A path to a resource. Defaults to `Route.defaultPath`.
        ///   - methods: An array of HTTP request methods. Defaults to all supported HTTP request methods.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        ///   - handler: A handler to call.
        /// - Returns: An array with one or more instances of `Route`.
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
        private func _request(
            _ path: String = Route.defaultPath,
            methods: Set<Request.Method> = Set(Request.Method.allCases),
            name: String = "",
            middleware: [Middleware] = .init(),
            handler: @escaping Route.Handler
        ) -> [Route] {
            var routes: [Route] = .init()

            for method in methods {
                if let route = Route(method: method, path: path, name: name, middleware: middleware, handler: handler) {
                    if let route = self.routes.insert(route) {
                        if let root = root {
                            if let route = root.routes.insert(route) {
                                routes.append(route)
                            }
                        } else {
                            routes.append(route)
                        }
                    }
                }
            }

            return routes
        }

        /// Creates a new child instance of `Builder` with `RouteCollection` to group related `Route`s.
        ///
        /// - Parameters:
        ///   - path: A path prefix to a resource. Defaults to `Route.defaultPath`.
        ///   - name: A name prefix for `Route`s. Defaults to an empty string.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        /// - Returns: A new child instance of `Builder`.
        public func grouped(
            _ path: String = Route.defaultPath,
            name: String = "",
            middleware: [Middleware] = .init()
        ) -> Builder? {
            guard let routes = RouteCollection(
                routes,
                path: path,
                name: name,
                middleware: routes.middleware + middleware
            ) else { return nil }
            if root == nil { root = self }
            let builder = Builder(routes)
            builder.root = root

            return builder
        }

        /// Creates a new child instance of `Builder` with `RouteCollection` to group related `Route`s.
        ///
        /// - Parameters:
        ///   - path: A path prefix to a resource. Defaults to `Route.defaultPath`.
        ///   - name: A name prefix for `Route`s. Defaults to an empty string.
        ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
        ///   - handler: A handler with a new child instance of `Builder` .
        public func group(
            _ path: String = Route.defaultPath,
            name: String = "",
            middleware: [Middleware] = .init(),
            handler: @escaping (Builder) -> Void
        ) {
            if let builder = grouped(path, name: name, middleware: middleware) { handler(builder) }
        }
    }
}
