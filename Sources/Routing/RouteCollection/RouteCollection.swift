import Foundation
import HTTP

/// `RouteCollection` helps to create `Route`s with path and name prefixes and
/// can assign an array of `Middleware` to apply before `Route`s' handler is called.
public final class RouteCollection {
    /// A typealias for the underlying storage type.
    public typealias DictionaryType = [Request.Method: [Route]]

    /// A path prefix for `Route`s.
    public private(set) var path: String

    /// A name prefix for `Route`s.
    public private(set) var name: String

    /// A read-only array of registered `Middleware`.
    public let middleware: [Middleware]

    private var routes: DictionaryType

    /// A `Builder`.
    public private(set) lazy var builder: Builder = .init(self)

    /// Initializes a new instance with defaults.
    public init() {
        routes = .init()
        path = Route.defaultPath
        name = ""
        middleware = .init()
    }

    /// Initializes a new instance.
    ///
    /// - Warning: It may return `nil` if the path prefix is invalid.
    /// - Parameters:
    ///   - routes: An instance of `RouteCollection`.
    ///   - path: A path prefix to a resource. Defaults to `/`.
    ///   - name: A name prefix for `Route`s. Defaults to an empty string.
    ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
    public init?(
        _ routes: RouteCollection = .init(),
        path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init()
    ) {
        self.routes = .init()
        var path = path
        self.path = path
        self.name = name
        self.middleware = middleware

        if routes.path == Route.defaultPath {
            path = Route.normalize(path: path)
        } else {
            path = Route.normalize(path: routes.path + Route.normalize(path: path))
        }

        let (isValid, _) = Route.isValid(path: path)
        if !isValid { return nil }
        insert(routes)
        self.path = path
        self.name = routes.name + name
    }

    /// Initializes a new instance with another `RouteCollection`.
    ///
    /// - Parameter routes: An instance of `RouteCollection`.
    public convenience init(_ routes: RouteCollection) {
        self.init(routes)!
    }

    /// Initializes a new instance with An array of `Route`s.
    ///
    /// - Parameter routes: An array of `Route`s.
    public convenience init(_ routes: [Route]) {
        self.init()
        insert(routes)
    }

    /// Initializes a new instance with a name prefix.
    ///
    /// - Parameter name: A name prefix for `Route`s.
    public convenience init(name: String) {
        self.init(name: name)!
    }

    /// Initializes a new instance.
    ///
    /// - Warning: It may return `nil` if the path prefix is invalid.
    /// - Parameters:
    ///   - routes: An array of `Route`s.
    ///   - path: A path prefix for `Route`s.
    ///   - name: A name prefix for `Route`s.
    public convenience init?(
        _ routes: [Route],
        path: String = Route.defaultPath,
        name: String = ""
    ) {
        self.init(path: path, name: name)
        insert(routes)
    }
}

extension RouteCollection {
    /// Gets or sets an array of `Route`s for a particular HTTP request method.
    ///
    /// - Parameter method: An HTTP request method.
    /// - Returns: An array of `Route`s for a particular HTTP request method.
    public subscript(method: Request.Method) -> [Route] {
        get { routes[method] ?? .init() }
        set { routes[method] = newValue }
    }

    /// Inserts an array of `Route`s.
    ///
    /// - Parameter routes: An array of `Route`s.
    private func insert(_ routes: [Route]) {
        for route in routes { insert(route) }
    }

    /// Inserts `Route`s from another `RouteCollection`.
    ///
    /// - Parameter routes: An instance of `RouteCollection`.
    public func insert(_ routes: RouteCollection) {
        for (_, methodRoutes) in routes { insert(methodRoutes) }
    }

    /// Inserts a `Route`.
    ///
    /// - Parameter route: An instance of `Route`.
    /// - Returns: An instance of an inserted `Route` or `nil` if the `Route` already exists.
    @discardableResult
    public func insert(_ route: Route) -> Route? {
        let separator = Route.defaultPath
        let route = Route(
            method: route.method,
            path: path == separator ? route.path : Route.normalize(path: path + route.path),
            name: name + route.name,
            middleware: middleware + route.middleware,
            handler: route.handler
        )!

        if !has(route) {
            self[route.method].append(route)
            return route
        }

        return nil
    }

    /// Checks if a `Route` exists or not.
    ///
    /// - Parameter route: An instance of `Route`.
    /// - Returns: `true` if a `Route` exists. `false` if it doesn't.
    public func has(_ route: Route) -> Bool {
        for (_, routes) in self where routes.contains(route) { return true }
        return false
    }

    /// Removes an array of `Route`s.
    ///
    /// - Parameter routes: An array of `Route`s.
    public func remove(_ routes: [Route]) {
        for route in routes { remove(route) }
    }

    /// Removes a `Route`.
    ///
    /// - Parameter route: An instance of `Route`.
    /// - Returns: An instance of a deleted `Route` or `nil` if the `Route` doesn't exist.
    @discardableResult
    public func remove(_ route: Route) -> Route? {
        for (method, routes) in self {
            if let index = routes.firstIndex(of: route) {
                let result = self[method].remove(at: index)
                if self[method].isEmpty { self.routes.removeValue(forKey: method) }
                return result
            }
        }

        return nil
    }
}

extension RouteCollection: Collection {
    /// See `Collection`.
    public typealias Index = DictionaryType.Index

    /// See `Collection`.
    public typealias Element = DictionaryType.Element

    /// See `Collection`.
    public var startIndex: Index { routes.startIndex }

    /// See `Collection`.
    public var endIndex: Index { routes.endIndex }

    /// See `Collection`.
    public subscript(index: Index) -> Element { routes[index] }

    /// See `Collection`.
    public func index(after index: Index) -> Index { routes.index(after: index) }
}
