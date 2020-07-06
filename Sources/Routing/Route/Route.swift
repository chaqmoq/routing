import class Foundation.NSRegularExpression
import struct HTTP.Request
import struct HTTP.Response

/// A route is a combination of an HTTP request method, path, name, a list of middleware, and handler.
public struct Route {
    /// A default `/` path.
    public static let defaultPath: String = "/"

    /// A regular expression pattern for the path components having a static text.
    static let textPattern = "[a-zA-Z0-9_~.-]+"

    /// A regular expression pattern for parameters' name.
    static let parameterNamePattern = "\\w+"

    /// A regular expression pattern for parameters.
    static let parameterPattern = """
    (\\{\(parameterNamePattern)(<[^\\/{}<>]+>)?(\\?(\(textPattern))?|!\(textPattern))?\\})+
    """

    /// A regular expression pattern for the path.
    static let pathPattern = "\(textPattern)|\(parameterPattern)"

    /// A typealias for the handler.
    public typealias Handler = (Request) -> Any

    /// An HTTP request method.
    public var method: Request.Method

    /// A path to a resource.
    public let path: String

    /// A regular expression pattern generated for the path.
    public private(set) var pattern: String

    /// A unique name for the route.
    public var name: String

    /// A read-only list of parameters extracted from the path.
    public var parameters: Set<Parameter>? { mutableParameters }

    /// A list of parameters extracted from the path.
    private var mutableParameters: Set<Parameter>?

    /// A list of registered middleware.
    public var middleware: [Middleware]

    /// A handler to call.
    public var handler: Handler

    /// Initializes a new instance with a default `/` path.
    ///
    /// - Parameters:
    ///   - method: An HTTP request method.
    ///   - name: A unique name for the route. Defaults to an empty string.
    ///   - middleware: A list of registered middleware. Defaults to an empty array.
    ///   - handler: A handler to call.
    public init(
        method: Request.Method,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Handler
    ) {
        self.method = method
        self.path = Route.defaultPath
        pattern = Route.generatePattern(for: self.path)
        self.name = name
        self.middleware = middleware
        self.handler = handler
    }

    /// Initializes a new instance or` nil`.
    ///
    /// - Warning: It may return `nil` if the path is invalid.
    /// - Parameters:
    ///   - method: An HTTP request method.
    ///   - path: A path to a resource.
    ///   - name: A unique name for the route. Defaults to an empty string.
    ///   - middleware: A list of registered middleware. Defaults to an empty array.
    ///   - handler: A handler to call.
    public init?(
        method: Request.Method,
        path: String,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Handler
    ) {
        self.method = method
        self.path = Route.normalize(path: path)
        pattern = self.path
        self.name = name
        self.middleware = middleware
        self.handler = handler
        let (isValid, parameters) = Route.isValid(path: self.path)

        if isValid {
            self.mutableParameters = parameters
            pattern = Route.generatePattern(for: self.path, with: self.mutableParameters)
            let separator = Route.defaultPath
            guard pattern == separator || (try? NSRegularExpression(pattern: pattern)) != nil else { return nil }
        } else {
            return nil
        }
    }
}

extension Route {
    /// Updates a parameter extracted from the path.
    ///
    /// - Parameter parameter: An instance of `Parameter`.
    /// - Returns: An updated instance of `Parameter` or `nil`
    @discardableResult
    mutating func updateParameter(_ parameter: Parameter) -> Parameter? {
        guard let index = mutableParameters?.firstIndex(of: parameter),
            let existingParameter = mutableParameters?[index] else { return nil }
        guard let newParameter = Parameter(
            name: existingParameter.name,
            value: parameter.value,
            requirement: existingParameter.requirement,
            defaultValue: existingParameter.defaultValue) else { return existingParameter }
        return mutableParameters?.update(with: newParameter)
    }
}

extension Route: Equatable {
    /// See `Equatable`.
    public static func ==(lhs: Route, rhs: Route) -> Bool {
        let isEqual = lhs.method == rhs.method && lhs.pattern == rhs.pattern
        if isEqual { return true }
        if lhs.name.isEmpty || rhs.name.isEmpty { return false }
        return lhs.name == rhs.name
    }
}

extension Route: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    public var description: String {
        var description = "method=\(method.rawValue)\npath=\(path)\npattern=\(pattern)"
        if !name.isEmpty { description.append("\nname=\(name)") }
        if let parameters = parameters { description.append("\nparameters=\(parameters)") }

        return description
    }
}
