import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request

public struct RouteCollection {
    public typealias DictionaryType = [Request.Method: [Route]]

    public private(set) var path: String
    public private(set) var name: String
    private var routes: DictionaryType

    public private(set) lazy var builder: Builder = .init(self)

    public init() {
        routes = .init()
        path = String(Route.pathComponentSeparator)
        name = ""
    }

    public init?(
        _ routes: RouteCollection = .init(),
        path: String = String(Route.pathComponentSeparator),
        name: String = ""
    ) {
        self.routes = .init()
        var path = path
        self.path = path
        self.name = name

        if routes.path == String(Route.pathComponentSeparator) {
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

    public init(_ routes: RouteCollection) {
        self.init(routes)!
    }

    public init(_ routes: [Route]) {
        self.init()
        insert(routes)
    }

    public init(name: String) {
        self.init(name: name)!
    }

    public init?(
        _ routes: [Route],
        path: String = String(Route.pathComponentSeparator),
        name: String = ""
    ) {
        self.init(path: path, name: name)
        insert(routes)
    }
}

extension RouteCollection {
    public subscript(method: Request.Method) -> [Route] {
        get { routes[method] ?? .init() }
        set { routes[method] = newValue }
    }

    private mutating func insert(_ routes: [Route]) {
        for route in routes { insert(route) }
    }

    public mutating func insert(_ routes: RouteCollection) {
        for (_, methodRoutes) in routes { insert(methodRoutes) }
    }

    @discardableResult
    public mutating func insert(_ route: Route) -> Route? {
        let separator = String(Route.pathComponentSeparator)
        let route = Route(
            method: route.method,
            path: path == separator ? route.path : Route.normalize(path: path + route.path),
            name: name + route.name,
            requestHandler: route.requestHandler
        )!

        if !has(route) {
            self[route.method].append(route)
            return route
        }

        return nil
    }

    public func has(_ route: Route) -> Bool {
        for (_, routes) in self where routes.contains(route) { return true }
        return false
    }

    public mutating func remove(_ routes: [Route]) {
        for route in routes { remove(route) }
    }

    @discardableResult
    public mutating func remove(_ route: Route) -> Route? {
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
    public typealias Index = DictionaryType.Index
    public typealias Element = DictionaryType.Element

    public var startIndex: Index { routes.startIndex }
    public var endIndex: Index { routes.endIndex }

    public subscript(index: Index) -> Element { routes[index] }
    public func index(after index: Index) -> Index { routes.index(after: index) }
}
