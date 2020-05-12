import class Foundation.NSRegularExpression
import struct HTTP.Request

public struct RouteCollection {
    public typealias DictionaryType = [Request.Method: Set<Route>]
    private var routes: DictionaryType
}

extension RouteCollection {
    public subscript(method: Request.Method) -> Set<Route> {
        get { routes[method] ?? .init() }
        set { routes[method] = newValue }
    }

    public mutating func insert(_ collection: RouteCollection) {
        for (method, routes) in collection {
            self.routes[method] = routes
        }
    }

    public mutating func insert(_ route: Route) {
        self[route.method].insert(route)
    }

    public mutating func remove(_ route: Route) {
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

extension RouteCollection: ExpressibleByDictionaryLiteral {
    public typealias Key = Request.Method
    public typealias Value = Set<Route>

    public init(dictionaryLiteral elements: (Request.Method, Set<Route>)...) {
        routes = .init()

        for (method, routes) in elements {
            self.routes[method] = routes
        }
    }
}
