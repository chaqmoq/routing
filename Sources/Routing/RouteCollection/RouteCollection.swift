import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request

public class RouteCollection {
    public typealias DictionaryType = [Request.Method: [Route]]

    public private(set) var path: String
    public private(set) var name: String
    private var routes: DictionaryType

    public private(set) lazy var builder: Builder = .init(self)

    public convenience init() {
        self.init()!
    }

    public convenience init(_ routes: RouteCollection) {
        self.init(routes)!
    }

    public convenience init(_ routes: [Route]) {
        self.init()!
        insert(routes)
    }

    public init?(path: String = String(Route.pathComponentSeparator), name: String = "") {
        routes = .init()
        self.name = name
        self.path = Route.normalize(path: path)
        let (isValid, _) = Route.isValid(path: self.path)
        if !isValid { return nil }
    }

    public init?(
        _ routes: RouteCollection,
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

    public convenience init?(
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

    private func insert(_ routes: [Route]) {
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
        self[route.method].contains(route)
    }

    public func remove(_ routes: [Route]) {
        for route in routes { remove(route) }
    }

    @discardableResult
    public func remove(_ route: Route) -> Route? {
        if let index = self[route.method].firstIndex(of: route) {
            return self[route.method].remove(at: index)
        }

        return nil
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
