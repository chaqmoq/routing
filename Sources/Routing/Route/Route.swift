import class Foundation.NSRegularExpression
import struct HTTP.Request
import struct HTTP.Response

public struct Route {
    public var method: Request.Method
    public private(set) var path: String
    public private(set) var pattern: String
    public var name: String
    public var parameters: Set<Parameter>? { mutableParameters }
    private var mutableParameters: Set<Parameter>?
    public var requestHandler: RequestHandler

    public init?(
        method: Request.Method,
        path: String = String(pathComponentSeparator),
        name: String = "",
        requestHandler: @escaping RequestHandler
    ) {
        self.method = method
        self.path = Route.normalize(path: path)
        pattern = self.path
        self.name = name
        self.requestHandler = requestHandler
        let (isValid, parameters) = Route.isValid(path: self.path)

        if isValid {
            self.mutableParameters = parameters
            pattern = Route.generatePattern(from: self.path, parameters: parameters)
            let separator = String(Route.pathComponentSeparator)
            guard pattern == separator || (try? NSRegularExpression(pattern: pattern)) != nil else { return nil }
        } else {
            return nil
        }
    }
}

extension Route {
    public typealias RequestHandler = (Request) -> Any
}

extension Route {
    @discardableResult
    public mutating func insertParameter(_ parameter: Parameter) -> (Bool, Parameter) {
        mutableParameters?.insert(parameter) ?? (false, parameter)
    }

    @discardableResult
    public mutating func updateParameter(_ parameter: Parameter) -> Parameter? {
        mutableParameters?.update(with: parameter)
    }
}

extension Route {
    public static let pathComponentSeparator: Character = "/"
    static let textPattern = "[a-zA-Z0-9_~.-]+"
    static let parameterNamePattern = "\\w+"
    static let parameterPattern = """
    (\\{\(parameterNamePattern)(<[^\\/{}<>]+>)?(\\?(\(textPattern))?|!\(textPattern))?\\})+
    """
    static let pathPattern = "\(textPattern)|\(parameterPattern)"
}

extension Route: Equatable {
    public static func ==(lhs: Route, rhs: Route) -> Bool {
        lhs.name == rhs.name || (lhs.method == rhs.method && lhs.pattern == rhs.pattern)
    }
}

extension Route: CustomStringConvertible {
    public var description: String {
        var description = "method=\(method.rawValue)\npath=\(path)"
        if !name.isEmpty { description.append("\nname=\(name)") }

        return description
    }
}
