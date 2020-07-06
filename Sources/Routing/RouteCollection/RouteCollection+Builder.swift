import struct HTTP.Request

extension RouteCollection {
    open class Builder {
        public var routes: RouteCollection
        private weak var root: Builder?

        public init(_ routes: RouteCollection = .init()) {
            self.routes = routes
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
