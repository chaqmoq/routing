import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request

public struct RouteCollection: Equatable {
    public typealias DictionaryType = [Request.Method: Set<Route>]

    static let pathPrefixPattern = "^[a-zA-Z0-9_~.-/]+$"
    static let namePrefixPattern = "^[a-zA-Z0-9_.-]+$"

    public let pathPrefix: String?
    public let namePrefix: String?
    private var routes: DictionaryType

    public init(pathPrefix: String? = nil, namePrefix: String? = nil) {
        routes = .init()
        self.pathPrefix = pathPrefix
        self.namePrefix = namePrefix
    }

    public init(_ routes: RouteCollection, pathPrefix: String? = nil, namePrefix: String? = nil) {
        self.routes = .init()
        self.pathPrefix = pathPrefix
        self.namePrefix = namePrefix
        insert(routes)
    }

    public init(_ routes: Set<Route>, pathPrefix: String? = nil, namePrefix: String? = nil) {
        self.routes = .init()
        self.pathPrefix = pathPrefix
        self.namePrefix = namePrefix
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

        if let pathPrefix = pathPrefix, let namePrefix = namePrefix {
            let pathPrefix = Route.normalize(path: pathPrefix)
            let separator = Route.pathComponentSeparator
            guard pathPrefix != String(separator),
                namePrefix != "",
                pathPrefix.starts(with: String(separator)),
                !pathPrefix.contains(String(separator) + String(separator)) else { return false }
            let pathPrefixRange = NSRange(location: 0, length: pathPrefix.utf8.count)
            let namePrefixRange = NSRange(location: 0, length: namePrefix.utf8.count)
            let pathPrefixPattern = RouteCollection.pathPrefixPattern
            let namePrefixPattern = RouteCollection.namePrefixPattern
            guard let pathPrefixRegex = try? NSRegularExpression(pattern: pathPrefixPattern),
                pathPrefixRegex.firstMatch(in: pathPrefix, range: pathPrefixRange) != nil,
                let namePrefixRegex = try? NSRegularExpression(pattern: namePrefixPattern),
                namePrefixRegex.firstMatch(in: namePrefix, range: namePrefixRange) != nil else { return false }
            route = Route(
                method: route.method,
                path: pathPrefix + route.path,
                name: namePrefix + (route.name ?? ""),
                requestHandler: route.requestHandler
            )!
        } else if let pathPrefix = pathPrefix {
            let separator = Route.pathComponentSeparator
            guard pathPrefix != String(separator),
                pathPrefix.starts(with: String(separator)),
                !pathPrefix.contains(String(separator) + String(separator)) else { return false }
            let pathPrefixPattern = RouteCollection.pathPrefixPattern
            let pathPrefix = Route.normalize(path: pathPrefix)
            guard let regex = try? NSRegularExpression(pattern: pathPrefixPattern) else { return false }
            let range = NSRange(location: 0, length: pathPrefix.utf8.count)
            guard regex.firstMatch(in: pathPrefix, range: range) != nil else { return false }
            route = Route(
                method: route.method,
                path: pathPrefix + route.path,
                name: route.name,
                requestHandler: route.requestHandler
            )!
        } else if let namePrefix = namePrefix {
            guard namePrefix != "" else { return false }
            let namePrefixPattern = RouteCollection.namePrefixPattern
            guard let regex = try? NSRegularExpression(pattern: namePrefixPattern) else { return false }
            let range = NSRange(location: 0, length: namePrefix.utf8.count)
            guard regex.firstMatch(in: namePrefix, range: range) != nil else { return false }
            route = Route(
                method: route.method,
                path: route.path,
                name: namePrefix + (route.name ?? ""),
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
