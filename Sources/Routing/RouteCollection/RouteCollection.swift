import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request

public class RouteCollection {
    public typealias DictionaryType = [Request.Method: Set<Route>]

    public let path: String
    public let name: String?
    private var routes: DictionaryType

    public private(set) lazy var builder: RouteCollectionBuilder = .init(self)

    public convenience init() {
        self.init(name: nil)!
    }

    public convenience init(_ routes: RouteCollection) {
        self.init(name: nil)!
        insert(routes)
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
        self.name = (routes.name ?? "") + (name ?? "")

        if routes.path.isEmpty {
            if path.isEmpty {
                self.path = String(Route.pathComponentSeparator)
            } else {
                self.path = Route.normalize(path: path)
            }
        } else {
            if path.isEmpty {
                self.path = routes.path
            } else {
                if routes.path == String(Route.pathComponentSeparator) {
                    self.path = Route.normalize(path: path)
                } else {
                    self.path = routes.path + Route.normalize(path: path)
                }
            }
        }

        let (isValid, _) = Route.isValid(path: self.path)
        if !isValid { return nil }
        insert(routes)
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
        let path: String

        if self.path == separator {
            path = route.path
        } else {
            let pathRange = NSRange(location: 0, length: self.path.utf8.count)
            let pathPattern = Route.pathPattern
            guard let pathRegex = try? NSRegularExpression(pattern: pathPattern),
                pathRegex.firstMatch(in: self.path, range: pathRange) != nil else { return nil }
            path = self.path + route.path
        }

        let route = Route(
            method: route.method,
            path: path,
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
