import class Foundation.NSRegularExpression
import struct HTTP.Request
import struct HTTP.Response

public struct Route {
    public typealias RequestHandler = (Request) -> Any

    public var method: Request.Method
    public private(set) var path: String
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
            pattern = Route.generatePattern(from: self.path, parameters: parameters)
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
    public mutating func updateParameter(named name: String, value: String) -> Parameter? {
        guard var parameter = getParameter(named: name) else { return nil }

        if parameter.defaultValue == nil {
            if !value.isEmpty {
                parameter.value = value
                return replaceParameter(with: parameter)
            }
        } else {
            parameter.value = value
            return replaceParameter(with: parameter)
        }

        return parameter
    }

    @discardableResult
    public mutating func updateParameter(named name: String, defaultValue: String) -> Parameter? {
        guard var parameter = getParameter(named: name) else { return nil }

        if let parameterDefaultValue = parameter.defaultValue {
            let oldParameter = parameter

            switch parameterDefaultValue {
            case .optional:
                parameter.defaultValue = .optional(defaultValue)
                return replaceParameter(oldParameter, with: parameter)
            case .forced:
                if !defaultValue.isEmpty {
                    parameter.defaultValue = .forced(defaultValue)
                    return replaceParameter(oldParameter, with: parameter)
                }
            }
        }

        return parameter
    }

    @discardableResult
    public mutating func updateParameter(
        named name: String,
        value: String,
        defaultValue: String
    ) -> Parameter? {
        guard var parameter = getParameter(named: name) else { return nil }

        if let parameterDefaultValue = parameter.defaultValue {
            let oldParameter = parameter
            parameter.value = value

            switch parameterDefaultValue {
            case .optional:
                parameter.defaultValue = .optional(defaultValue)
                return replaceParameter(oldParameter, with: parameter)
            case .forced:
                if defaultValue.isEmpty {
                    return replaceParameter(with: parameter)
                } else {
                    parameter.defaultValue = .forced(defaultValue)
                    return replaceParameter(oldParameter, with: parameter)
                }
            }
        } else {
            if !value.isEmpty {
                parameter.value = value
                return replaceParameter(with: parameter)
            }
        }

        return parameter
    }

    private func getParameter(named name: String) -> Parameter? {
        if name.isEmpty { return nil }
        return mutableParameters?.first(where: { $0.name == name })
    }

    private mutating func replaceParameter(
        _ oldParameter: Parameter? = nil,
        with newParameter: Parameter
    ) -> Parameter? {
        if let oldParameter = oldParameter {
            let parameter = mutableParameters?.update(with: newParameter)
            path = path.replacingOccurrences(of: "\(oldParameter)", with: "\(newParameter)")
            pattern = Route.generatePattern(from: path, parameters: mutableParameters)

            return parameter
        }

        return mutableParameters?.update(with: newParameter)
    }
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
