import HTTP

/// A ``RouteBuilder`` that can create child groups, allowing routes to be
/// organised under a shared path prefix, name prefix, and middleware stack.
///
/// ```swift
/// router.group("/api/v1", name: "api.v1.", middleware: [AuthMiddleware()]) { v1 in
///     v1.get("/users")      { req in … }   // registered as /api/v1/users
///     v1.get("/users/{id}") { req in … }   // registered as /api/v1/users/{id}
/// }
/// ```
open class RouteGroup: RouteBuilder {
    /// Returns a new `RouteGroup` whose path, name, and middleware are
    /// prepended with the values from the receiver.
    ///
    /// - Parameters:
    ///   - path:       Additional path prefix (must be valid per ``Route/isValid(path:)``).
    ///   - name:       Additional name prefix.
    ///   - middleware: Middleware to prepend to every route in the new group.
    /// - Returns: A child `RouteGroup`, or `nil` if `path` is invalid.
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

    /// Creates a child group and passes it to `handler` for route registration.
    ///
    /// Equivalent to calling ``grouped(_:name:middleware:)`` and immediately
    /// registering routes via a closure.  If `path` is invalid the closure is
    /// not called.
    ///
    /// - Parameters:
    ///   - path:       Additional path prefix.
    ///   - name:       Additional name prefix.
    ///   - middleware: Middleware to prepend to every route registered in `handler`.
    ///   - handler:    Closure that receives the child group and registers routes on it.
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
