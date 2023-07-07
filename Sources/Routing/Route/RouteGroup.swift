import HTTP

open class RouteGroup: RouteBuilder {
    var router: Router?

    public func grouped(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init()
    ) -> RouteGroup? {
        var path = Route.normalize(path: path)
        let (isValid, _) = Route.isValid(path: path)
        guard isValid else { return nil }

        if !self.path.isEmpty {
            path = self.path + path
        }

        let group = RouteGroup(path: path, name: self.name + name, middleware: self.middleware + middleware)
        group.router = router

        return group
    }

    public func group(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping (RouteGroup) -> Void
    ) {
        if let group = grouped(path, name: name, middleware: middleware) {
            handler(group)
        }
    }

    override func _request(
        _ path: String = Route.defaultPath,
        methods: Set<Request.Method> = Set(Request.Method.allCases),
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Route.Handler
    ) -> [Route] {
        let routes = super._request(path, methods: methods, name: name, middleware: middleware, handler: handler)

        for route in routes {
            router?.register(route: route)
        }

        return routes
    }
}
