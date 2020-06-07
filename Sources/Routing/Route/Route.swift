import class Foundation.NSRegularExpression
import struct HTTP.Request
import struct HTTP.Response

public struct Route {
    public typealias RequestHandler = (Request) -> Any

    public var method: Request.Method
    public let path: String
    public private(set) var pattern: String
    public var name: String
    public var parameters: Set<Parameter>? { mutableParameters }
    private var mutableParameters: Set<Parameter>?
    public var requestHandler: RequestHandler

    public init(method: Request.Method, name: String = "", requestHandler: @escaping RequestHandler) {
        self.method = method
        self.path = String(Route.pathComponentSeparator)
        pattern = Route.generatePattern(from: self.path)
        self.name = name
        self.requestHandler = requestHandler
    }

    public init?(method: Request.Method, path: String, name: String = "", requestHandler: @escaping RequestHandler) {
        self.method = method
        self.path = Route.normalize(path: path)
        pattern = self.path
        self.name = name
        self.requestHandler = requestHandler
        let (isValid, parameters) = Route.isValid(path: self.path)

        if isValid {
            self.mutableParameters = parameters
            pattern = Route.generatePattern(from: self.path, parameters: self.mutableParameters)
            let separator = String(Route.pathComponentSeparator)
            guard pattern == separator || (try? NSRegularExpression(pattern: pattern)) != nil else { return nil }
        } else {
            return nil
        }
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

extension Route {
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
    public static func ==(lhs: Route, rhs: Route) -> Bool {
        let isEqual = lhs.method == rhs.method && lhs.pattern == rhs.pattern
        if isEqual { return true }
        if lhs.name.isEmpty || rhs.name.isEmpty { return false }
        return lhs.name == rhs.name
    }
}

extension Route: CustomStringConvertible {
    public var description: String {
        var description = "method=\(method.rawValue)\npath=\(path)"
        if !name.isEmpty { description.append("\nname=\(name)") }

        return description
    }
}
