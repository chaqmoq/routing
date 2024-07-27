import HTTP

open class RouteGroup: RouteBuilder {
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
}
