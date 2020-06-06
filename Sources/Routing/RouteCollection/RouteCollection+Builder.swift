import struct HTTP.Request

extension RouteCollection {
    public class Builder {
        public var routes: RouteCollection
        private weak var root: Builder?

        public init(_ routes: RouteCollection = .init()) {
            self.routes = routes
        }

        @discardableResult
        public func delete(
            _ path: String = String(Route.pathComponentSeparator),
            name: String = "",
            handler: @escaping Route.RequestHandler
        ) -> Route? {
            makeRequest(path, methods: [.DELETE], name: name, handler: handler).first
        }

        @discardableResult
        public func get(
            _ path: String = String(Route.pathComponentSeparator),
            name: String = "",
            handler: @escaping Route.RequestHandler
        ) -> Route? {
            makeRequest(path, methods: [.GET], name: name, handler: handler).first
        }

        @discardableResult
        public func head(
            _ path: String = String(Route.pathComponentSeparator),
            name: String = "",
            handler: @escaping Route.RequestHandler
        ) -> Route? {
            makeRequest(path, methods: [.HEAD], name: name, handler: handler).first
        }

        @discardableResult
        public func options(
            _ path: String = String(Route.pathComponentSeparator),
            name: String = "",
            handler: @escaping Route.RequestHandler
        ) -> Route? {
            makeRequest(path, methods: [.OPTIONS], name: name, handler: handler).first
        }

        @discardableResult
        public func patch(
            _ path: String = String(Route.pathComponentSeparator),
            name: String = "",
            handler: @escaping Route.RequestHandler
        ) -> Route? {
            makeRequest(path, methods: [.PATCH], name: name, handler: handler).first
        }

        @discardableResult
        public func post(
            _ path: String = String(Route.pathComponentSeparator),
            name: String = "",
            handler: @escaping Route.RequestHandler
        ) -> Route? {
            makeRequest(path, methods: [.POST], name: name, handler: handler).first
        }

        @discardableResult
        public func put(
            _ path: String = String(Route.pathComponentSeparator),
            name: String = "",
            handler: @escaping Route.RequestHandler
        ) -> Route? {
            makeRequest(path, methods: [.PUT], name: name, handler: handler).first
        }

        @discardableResult
        public func request(
            _ path: String = String(Route.pathComponentSeparator),
            methods: Set<Request.Method>? = nil,
            handler: @escaping Route.RequestHandler
        ) -> [Route] {
            makeRequest(path, methods: methods, handler: handler)
        }

        @discardableResult
        private func makeRequest(
            _ path: String = String(Route.pathComponentSeparator),
            methods: Set<Request.Method>? = nil,
            name: String = "",
            handler: @escaping Route.RequestHandler
        ) -> [Route] {
            let methods = methods ?? Set(Request.Method.allCases)
            var routes: [Route] = []

            for method in methods {
                if let route = Route(method: method, path: path, name: name, requestHandler: handler) {
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

        public func grouped(_ path: String = String(Route.pathComponentSeparator), name: String = "") -> Builder? {
            guard let routes = RouteCollection(routes, path: path, name: name) else { return nil }
            if root == nil { root = self }
            let builder = Builder(routes)
            builder.root = root

            return builder
        }

        public func group(
            _ path: String = String(Route.pathComponentSeparator),
            name: String = "",
            handler: @escaping (Builder) -> Void
        ) {
            if let builder = grouped(path, name: name) { handler(builder) }
        }
    }
}