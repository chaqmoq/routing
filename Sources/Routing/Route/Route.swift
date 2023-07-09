import Foundation
import HTTP

/// A combination of an HTTP request method, path, name, an array of `Middleware`, and a handler that points to a location where a resource exists.
public struct Route {
    /// A default path `/`.
    public static let defaultPath = "/"

    static let textPattern = "[a-zA-Z0-9_~.-]+"
    static let parameterNamePattern = "\\w+"
    static let parameterPattern = """
    (\\{\(parameterNamePattern)(<[^\\/{}<>]+>)?(\\?(\(textPattern))?|!\(textPattern))?\\})+
    """
    static let pathPattern = "\(textPattern)|\(parameterPattern)"

    /// A typealias for the handler.
    public typealias Handler = (Request) async throws -> Encodable

    /// An HTTP request method.
    public var method: Request.Method

    /// A path to a resource.
    public let path: String

    /// A regular expression pattern generated for the path.
    public private(set) var pattern: String

    /// A unique name for `Route`.
    public var name: String

    /// A read-only set of parameters extracted from the path.
    public var parameters: Set<Parameter> { mutableParameters }

    private var mutableParameters: Set<Parameter>

    /// An array of registered `Middleware`.
    public var middleware: [Middleware]

    /// A handler to call.
    public var handler: Handler

    private var dateFormatter = ISO8601DateFormatter()

    /// Initializes a new instance with the `defaultPath`.
    ///
    /// - Parameters:
    ///   - method: An HTTP request method.
    ///   - name: A unique name for `Route`. Defaults to an empty string.
    ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
    ///   - handler: A handler to call.
    public init(
        method: Request.Method,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Handler
    ) {
        self.method = method
        path = Route.defaultPath
        pattern = Route.generatePattern(for: path)
        mutableParameters = .init()
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
    ///   - name: A unique name for `Route`. Defaults to an empty string.
    ///   - middleware: An array of registered `Middleware`. Defaults to an empty array.
    ///   - handler: A handler to call.
    public init?(
        method: Request.Method,
        path: String,
        name: String = "",
        middleware: [Middleware] = .init(),
        handler: @escaping Handler
    ) {
        self.method = method
        self.path = path
        pattern = self.path
        self.name = name
        self.middleware = middleware
        self.handler = handler
        let (isValid, parameters) = Route.isValid(path: self.path)

        if isValid {
            mutableParameters = parameters
            pattern = Route.generatePattern(for: self.path, with: mutableParameters)
            let separator = Route.defaultPath
            guard pattern == separator || (try? NSRegularExpression(pattern: pattern)) != nil else { return nil }
        } else {
            return nil
        }
    }
}

extension Route: Equatable {
    /// See `Equatable`.
    public static func == (lhs: Route, rhs: Route) -> Bool {
        let isEqual = lhs.method == rhs.method && lhs.pattern == rhs.pattern
        if isEqual { return true }
        if lhs.name.isEmpty || rhs.name.isEmpty { return false }
        return lhs.name == rhs.name
    }
}

extension Route: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    public var description: String {
        var description = "method=\(method.rawValue),\npath=\(path),\npattern=\(pattern)"
        if !name.isEmpty { description.append(",\nname=\(name)") }
        if !parameters.isEmpty { description.append(",\nparameters=\(parameters)") }

        return description
    }
}

extension Route {
    /// Gets a parameter value for a parameter name.
    ///
    /// - Parameter parameter: A parameter name.
    /// - Returns: A parameter value.
    public subscript<T>(parameter name: String) -> T? {
        guard let string = parameters.first(where: { $0.name == name })?.value else { return nil }
        let type = T.self

        if type == String.self {
            return string as? T
        } else if type == Int.self {
            return Int(string) as? T
        } else if type == Int8.self {
            return Int8(string) as? T
        } else if type == Int16.self {
            return Int16(string) as? T
        } else if type == Int32.self {
            return Int32(string) as? T
        } else if type == Int64.self {
            return Int64(string) as? T
        } else if type == UInt.self {
            return UInt(string) as? T
        } else if type == UInt8.self {
            return UInt8(string) as? T
        } else if type == UInt16.self {
            return UInt16(string) as? T
        } else if type == UInt32.self {
            return UInt32(string) as? T
        } else if type == UInt64.self {
            return UInt64(string) as? T
        } else if type == UUID.self {
            return UUID(uuidString: string) as? T
        } else if type == Double.self {
            return Double(string) as? T
        } else if type == Float.self {
            return Float(string) as? T
        } else if type == Bool.self {
            return Bool(string) as? T
        } else if type == URL.self {
            return URL(string: string) as? T
        } else if type == Date.self {
            return dateFormatter.date(from: string) as? T
        }
        // TODO: consider converting to dictionary and array

        return nil
    }
}

extension Route {
    /// Checks if a path is valid or not.
    ///
    /// - Parameter path: A path to a resource.
    /// - Returns: If the path is valid, it returns `true` and a set of extracted parameters. Otherwise, it returns `false` and an empty `Set<Parameter>`.
    public static func isValid(path: String) -> (Bool, Set<Parameter>) {
        let separator = Route.defaultPath
        if path == separator { return (true, .init()) }
        if !path.starts(with: separator) || path.contains(separator + separator) { return (false, .init()) }
        guard let regex = try? NSRegularExpression(pattern: Route.pathPattern) else { return (false, .init()) }
        let pathComponents = path.components(separatedBy: separator).filter { $0 != "" }
        var parameters = Set<Parameter>()

        for pathComponent in pathComponents {
            let range = NSRange(location: 0, length: pathComponent.utf8.count)
            let matches = regex.matches(in: pathComponent, range: range)
            var matchesString = ""

            for match in matches {
                if let range = Range(match.range, in: pathComponent) {
                    let pathComponentPart = String(pathComponent[range])

                    if pathComponentPart.hasPrefix(String(Parameter.nameEnclosingSymbols.0)) {
                        let requirementEnclosingSymbols = Parameter.requirementEnclosingSymbols
                        let startRange = pathComponentPart.range(of: String(requirementEnclosingSymbols.0))
                        let endRange = pathComponentPart.range(of: String(requirementEnclosingSymbols.1))

                        if let startIndex = startRange?.upperBound, let endIndex = endRange?.lowerBound {
                            let pattern = String(pathComponentPart[startIndex ..< endIndex])
                            if (try? NSRegularExpression(pattern: pattern)) == nil { return (false, .init()) }
                        }
                    }

                    if let parameter = Route.createParameter(from: pathComponentPart) {
                        parameters.insert(parameter)
                    }

                    matchesString.append(pathComponentPart)
                }
            }

            if matchesString != pathComponent { return (false, .init()) }
        }

        return (true, parameters)
    }

    /// Generates a regular expression pattern for the path with parameters.
    ///
    /// - Parameters:
    ///   - path: A path to a resource.
    ///   - parameters: A set of parameters.
    /// - Returns: A regular expression pattern.
    public static func generatePattern(for path: String, with parameters: Set<Parameter> = .init()) -> String {
        var pattern = path
        let separator = Route.defaultPath

        for parameter in parameters {
            if parameter.defaultValue != nil,
               let range = pattern.range(of: "\(separator)\(parameter)"),
               range.upperBound == pattern.endIndex {
                var parameterPattern = parameter.pattern
                parameterPattern.insert(
                    contentsOf: separator,
                    at: parameterPattern.index(parameterPattern.startIndex, offsetBy: 1)
                )
                pattern = pattern.replacingOccurrences(
                    of: "\(separator)\(parameter)",
                    with: parameterPattern
                )
            }

            pattern = pattern.replacingOccurrences(of: "\(parameter)", with: parameter.pattern)
        }

        return pattern
    }

    /// Creates a new instance of `Parameter` based on the parameter pattern `{name<requirement>?defaultValue}`.
    ///
    /// - Parameter part: A part of a path component.
    /// - Returns: A new instance of `Parameter` or `nil`.
    public static func createParameter(from part: String) -> Parameter? {
        if var nameStartIndex = part.firstIndex(of: Parameter.nameEnclosingSymbols.0),
           var nameEndIndex = part.firstIndex(of: Parameter.nameEnclosingSymbols.1)
        {
            nameStartIndex = part.index(after: nameStartIndex)
            var requirement = ""
            var defaultValue: Parameter.DefaultValue?

            if var requirementStartIndex = part.firstIndex(of: Parameter.requirementEnclosingSymbols.0),
               let requirementEndIndex = part.firstIndex(of: Parameter.requirementEnclosingSymbols.1)
            {
                if var defaultValueStartIndex = part.firstIndex(of: Parameter.optionalSymbol) {
                    let defaultValueEndIndex = nameEndIndex
                    defaultValueStartIndex = part.index(after: defaultValueStartIndex)
                    defaultValue = .optional(String(part[defaultValueStartIndex ..< defaultValueEndIndex]))
                } else if var defaultValueStartIndex = part.firstIndex(of: Parameter.forcedSymbol) {
                    let defaultValueEndIndex = nameEndIndex
                    defaultValueStartIndex = part.index(after: defaultValueStartIndex)
                    defaultValue = .forced(String(part[defaultValueStartIndex ..< defaultValueEndIndex]))
                }

                nameEndIndex = requirementStartIndex
                requirementStartIndex = part.index(after: requirementStartIndex)
                requirement = String(part[requirementStartIndex ..< requirementEndIndex])
            } else if var defaultValueStartIndex = part.firstIndex(of: Parameter.optionalSymbol) {
                let defaultValueEndIndex = nameEndIndex
                nameEndIndex = defaultValueStartIndex
                defaultValueStartIndex = part.index(after: defaultValueStartIndex)
                defaultValue = .optional(String(part[defaultValueStartIndex ..< defaultValueEndIndex]))
            } else if var defaultValueStartIndex = part.firstIndex(of: Parameter.forcedSymbol) {
                let defaultValueEndIndex = nameEndIndex
                nameEndIndex = defaultValueStartIndex
                defaultValueStartIndex = part.index(after: defaultValueStartIndex)
                defaultValue = .forced(String(part[defaultValueStartIndex ..< defaultValueEndIndex]))
            }

            return Parameter(
                name: String(part[nameStartIndex ..< nameEndIndex]),
                requirement: requirement,
                defaultValue: defaultValue
            )
        }

        return nil
    }

    /// Updates a parameter's value extracted from the path.
    ///
    /// - Parameter parameter: An instance of `Parameter`.
    /// - Returns: An updated instance of `Parameter` or `nil`.
    @discardableResult
    public mutating func updateParameter(_ parameter: Parameter) -> Parameter? {
        guard let index = mutableParameters.firstIndex(of: parameter) else { return nil }
        let existingParameter = mutableParameters[index]
        guard let newParameter = Parameter(
            name: existingParameter.name,
            value: parameter.value,
            requirement: existingParameter.requirement,
            defaultValue: existingParameter.defaultValue
        ) else { return existingParameter }
        return mutableParameters.update(with: newParameter)
    }
}
