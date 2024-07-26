import HTTP

open class RouteGroup: RouteBuilder {
    var router: Router?

    public func grouped(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init()
    ) -> RouteGroup? {
        let (isValid, _) = Route.isValid(path: path)

        if isValid {
            let group = RouteGroup(
                path: self.path.appending(path: path),
                name: self.name + name,
                middleware: self.middleware + middleware
            )
            group?.router = router

            return group
        }

        return nil
    }

    public func group(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping (RouteGroup) -> Void
    ) {
        if let group = grouped(
            path,
            name: name,
            middleware: middleware
        ) {
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
        let routes = super._request(
            path,
            methods: methods,
            name: name,
            middleware: middleware,
            handler: handler
        )

        for route in routes {
            router?.register(route: route)
        }

        return routes
    }
}
