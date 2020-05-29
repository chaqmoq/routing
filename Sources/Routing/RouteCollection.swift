import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request

public struct RouteCollection: Equatable {
    public typealias DictionaryType = [Request.Method: Set<Route>]

    static let pathPattern = "^[a-zA-Z0-9_~.-/]+$"
    static let namePattern = "^[a-zA-Z0-9_.-]+$"

    public let path: String?
    public let name: String?
    private var routes: DictionaryType

    public init(path: String? = nil, name: String? = nil) {
        routes = .init()
        self.path = path
        self.name = name
    }

    public init(_ routes: RouteCollection, path: String? = nil, name: String? = nil) {
        self.routes = .init()
        self.path = path
        self.name = name
        insert(routes)
    }

    public init(_ routes: Set<Route>, path: String? = nil, name: String? = nil) {
        self.routes = .init()
        self.path = path
        self.name = name
        insert(routes)
    }

    public subscript(method: Request.Method) -> Set<Route> {
        get { routes[method] ?? .init() }
        set { routes[method] = newValue }
    }

    public mutating func insert(_ routes: RouteCollection) {
        for (_, methodRoutes) in routes { insert(methodRoutes) }
    }

    public mutating func insert(_ routes: Set<Route>) {
        for route in routes { insert(route) }
    }

    @discardableResult
    public mutating func insert(_ route: Route) -> Bool {
        var route = route

        if let path = path, let name = name {
            let path = Route.normalize(path: path)
            let separator = Route.pathComponentSeparator
            guard path != String(separator),
                name != "",
                path.starts(with: String(separator)),
                !path.contains(String(separator) + String(separator)) else { return false }
            let pathRange = NSRange(location: 0, length: path.utf8.count)
            let nameRange = NSRange(location: 0, length: name.utf8.count)
            let pathPattern = RouteCollection.pathPattern
            let namePattern = RouteCollection.namePattern
            guard let pathRegex = try? NSRegularExpression(pattern: pathPattern),
                pathRegex.firstMatch(in: path, range: pathRange) != nil,
                let nameRegex = try? NSRegularExpression(pattern: namePattern),
                nameRegex.firstMatch(in: name, range: nameRange) != nil else { return false }
            route = Route(
                method: route.method,
                path: path + route.path,
                name: name + (route.name ?? ""),
                requestHandler: route.requestHandler
            )!
        } else if let path = path {
            let separator = Route.pathComponentSeparator
            guard path != String(separator),
                path.starts(with: String(separator)),
                !path.contains(String(separator) + String(separator)) else { return false }
            let pathPattern = RouteCollection.pathPattern
            let path = Route.normalize(path: path)
            guard let regex = try? NSRegularExpression(pattern: pathPattern) else { return false }
            let range = NSRange(location: 0, length: path.utf8.count)
            guard regex.firstMatch(in: path, range: range) != nil else { return false }
            route = Route(
                method: route.method,
                path: path + route.path,
                name: route.name,
                requestHandler: route.requestHandler
            )!
        } else if let name = name {
            guard name != "" else { return false }
            let namePattern = RouteCollection.namePattern
            guard let regex = try? NSRegularExpression(pattern: namePattern) else { return false }
            let range = NSRange(location: 0, length: name.utf8.count)
            guard regex.firstMatch(in: name, range: range) != nil else { return false }
            route = Route(
                method: route.method,
                path: route.path,
                name: name + (route.name ?? ""),
                requestHandler: route.requestHandler
            )!
        }

        if !routes.contains(where: { $0.value.contains(route) }) {
            return self[route.method].insert(route).0
        }

        return false
    }

    public mutating func remove(_ routes: Set<Route>) {
        for route in routes { remove(route) }
    }

    @discardableResult
    public mutating func remove(_ route: Route) -> Bool {
        self[route.method].remove(route) != nil
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
