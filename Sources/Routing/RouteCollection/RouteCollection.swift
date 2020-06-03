import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request

public class RouteCollection {
    public typealias DictionaryType = [Request.Method: Set<Route>]

    public private(set) var path: String
    public private(set) var name: String?
    private var routes: DictionaryType

    public private(set) lazy var builder: RouteCollectionBuilder = .init(self)

    public convenience init() {
        self.init(name: nil)!
    }

    public convenience init(_ routes: RouteCollection) {
        self.init(routes, name: nil)!
    }

    public convenience init(_ routes: Set<Route>) {
        self.init(name: nil)!
        insert(routes)
    }

    public init?(path: String = String(Route.pathComponentSeparator), name: String? = nil) {
        routes = .init()
        self.name = name

        if path.isEmpty {
            self.path = String(Route.pathComponentSeparator)
        } else {
            self.path = Route.normalize(path: path)
            let (isValid, _) = Route.isValid(path: self.path)
            if !isValid { return nil }
        }
    }

    public init?(
        _ routes: RouteCollection,
        path: String = String(Route.pathComponentSeparator),
        name: String? = nil
    ) {
        self.routes = .init()
        var path = path
        var name = name
        self.path = path
        self.name = name

        if routes.path.isEmpty {
            if path.isEmpty {
                path = String(Route.pathComponentSeparator)
            } else {
                path = Route.normalize(path: path)
            }
        } else {
            if path.isEmpty {
                path = routes.path
            } else {
                if routes.path == String(Route.pathComponentSeparator) {
                    path = Route.normalize(path: path)
                } else {
                    path = Route.normalize(path: routes.path + Route.normalize(path: path))
                }
            }
        }

        if let parentName = routes.name {
            if let childName = name {
                name = parentName + childName
            } else {
                name = parentName
            }
        } else {
            if let childName = name {
                name = childName
            } else {
                name = nil
            }
        }

        let (isValid, _) = Route.isValid(path: path)
        if !isValid { return nil }
        insert(routes)
        self.path = path
        self.name = name
    }

    public convenience init?(
        _ routes: Set<Route>,
        path: String = String(Route.pathComponentSeparator),
        name: String? = nil
    ) {
        self.init(path: path, name: name)
        insert(routes)
    }
}

extension RouteCollection {
    public subscript(method: Request.Method) -> Set<Route> {
        get { routes[method] ?? .init() }
        set { routes[method] = newValue }
    }

    private func insert(_ routes: Set<Route>) {
        for route in routes { insert(route) }
    }

    public func insert(_ routes: RouteCollection) {
        for (_, methodRoutes) in routes { insert(methodRoutes) }
    }

    @discardableResult
    public func insert(_ route: Route) -> Route? {
        let separator = String(Route.pathComponentSeparator)
        let route = Route(
            method: route.method,
            path: self.path == separator ? route.path : self.path + route.path,
            name: (name ?? "") + (route.name ?? ""),
            requestHandler: route.requestHandler
        )!

        if !routes.contains(where: { $0.value.contains(route) }) && self[route.method].insert(route).0 {
            return route
        }

        return nil
    }

    public func remove(_ routes: Set<Route>) {
        for route in routes { remove(route) }
    }

    @discardableResult
    public func remove(_ route: Route) -> Route? {
        self[route.method].remove(route)
    }
}

extension RouteCollection: Collection {
    public typealias Index = DictionaryType.Index
    public typealias Element = DictionaryType.Element

    public var startIndex: Index { routes.startIndex }
    public var endIndex: Index { routes.endIndex }

    public subscript(index: Index) -> RouteCollection.Element { routes[index] }
    public func index(after index: Index) -> Index { routes.index(after: index) }
}
