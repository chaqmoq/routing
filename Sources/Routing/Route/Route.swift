import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request
import struct HTTP.Response

public struct Route {
    public typealias RequestHandler = (Request) -> Any

    static let textPattern = "[a-zA-Z0-9_~.-]+"
    static let parameterPattern = "(\\{\\w+(<[^\\/{}<>]+>)?(\\?([a-zA-Z0-9_~.-]+)?|![a-zA-Z0-9_~.-]+)?\\})+"
    static let pathPattern = "\(textPattern)|\(parameterPattern)"

    public var method: Request.Method
    public let path: String
    public var name: String?
    public var parameters: Set<Parameter>?
    public var requestHandler: RequestHandler

    public init?(
        method: Request.Method,
        path: String = "",
        name: String? = nil,
        requestHandler: @escaping RequestHandler
    ) {
        self.method = method
        self.path = path.last == "/" ? String(path.dropLast()) : path
        self.name = name
        self.requestHandler = requestHandler

        let (isValid, parameters) = validate(path: path)

        if isValid {
            self.parameters = parameters
        } else {
            return nil
        }
    }
}

extension Route: Hashable {
    public static func ==(lhs: Route, rhs: Route) -> Bool {
        lhs.method == rhs.method && lhs.path == rhs.path
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(method)
        hasher.combine(path)
    }
}

extension Route: CustomStringConvertible {
    public var description: String {
        var description = "method=\(method.rawValue)\npath=\(path)"
        if let name = name { description.append("\nname=\(name)") }

        return description
    }
}

extension Route {
    public func validate(path: String) -> (Bool, Set<Route.Parameter>?) {
        if path == "" { return (true, nil) }
        if !path.starts(with: "/") || path.contains("//") { return (false, nil) }
        guard let regex = try? NSRegularExpression(pattern: Route.pathPattern) else { return (false, nil) }
        let pathComponents = path.components(separatedBy: "/").filter({ $0 != "" })
        var parameters: Set<Route.Parameter>?

        for pathComponent in pathComponents {
            let range = NSRange(location: 0, length: pathComponent.utf8.count)
            let matches = regex.matches(in: pathComponent, range: range)

            if matches.isEmpty {
                return (false, nil)
            } else {
                var matchesString = ""

                for match in matches {
                    let pathComponentPart = String(pathComponent[Range(match.range, in: pathComponent)!])

                    if pathComponentPart.hasPrefix(String(Parameter.nameEnclosingSymbols.0)) {
                        if var startIndex = pathComponentPart.range(of: String(Parameter.requirementEnclosingSymbols.0))?.lowerBound,
                            var endIndex = pathComponentPart.range(of: String(Parameter.requirementEnclosingSymbols.1))?.upperBound {
                            startIndex = pathComponentPart.index(after: startIndex)
                            endIndex = pathComponentPart.index(before: endIndex)
                            let pattern = String(pathComponentPart[startIndex..<endIndex])
                            let regex = try? NSRegularExpression(pattern: pattern)
                            if regex == nil { return (false, nil) }
                        }
                    }

                    if let parameter = extractParameter(from: pathComponentPart) {
                        if parameters == nil { parameters = [] }
                        parameters?.insert(parameter)
                    }

                    matchesString.append(pathComponentPart)
                }

                if matchesString != pathComponent { return (false, nil) }
            }
        }

        return (true, parameters)
    }

    func extractParameter(from pathComponentPart: String) -> Parameter? {
        if var nameStartIndex = pathComponentPart.firstIndex(of: Parameter.nameEnclosingSymbols.0),
            var nameEndIndex = pathComponentPart.firstIndex(of: Parameter.nameEnclosingSymbols.1) {
            nameStartIndex = pathComponentPart.index(after: nameStartIndex)
            var parameter = Parameter(name: String(pathComponentPart[nameStartIndex..<nameEndIndex]))

            if var requirementStartIndex = pathComponentPart.firstIndex(of: Parameter.requirementEnclosingSymbols.0),
                let requirementEndIndex = pathComponentPart.firstIndex(of: Parameter.requirementEnclosingSymbols.1) {
                if var defaultValueStartIndex = pathComponentPart.firstIndex(of: Parameter.optionalSymbol) {
                    let defaultValueEndIndex = nameEndIndex
                    defaultValueStartIndex = pathComponentPart.index(after: defaultValueStartIndex)
                    parameter.defaultValue = .optional(String(pathComponentPart[defaultValueStartIndex..<defaultValueEndIndex]))
                } else if var defaultValueStartIndex = pathComponentPart.firstIndex(of: Parameter.forcedSymbol) {
                    let defaultValueEndIndex = nameEndIndex
                    defaultValueStartIndex = pathComponentPart.index(after: defaultValueStartIndex)
                    parameter.defaultValue = .forced(String(pathComponentPart[defaultValueStartIndex..<defaultValueEndIndex]))
                }

                nameEndIndex = requirementStartIndex
                requirementStartIndex = pathComponentPart.index(after: requirementStartIndex)
                parameter.requirement = String(pathComponentPart[requirementStartIndex..<requirementEndIndex])
            } else if var defaultValueStartIndex = pathComponentPart.firstIndex(of: Parameter.optionalSymbol) {
                let defaultValueEndIndex = nameEndIndex
                nameEndIndex = defaultValueStartIndex
                defaultValueStartIndex = pathComponentPart.index(after: defaultValueStartIndex)
                parameter.defaultValue = .optional(String(pathComponentPart[defaultValueStartIndex..<defaultValueEndIndex]))
            } else if var defaultValueStartIndex = pathComponentPart.firstIndex(of: Parameter.forcedSymbol) {
                let defaultValueEndIndex = nameEndIndex
                nameEndIndex = defaultValueStartIndex
                defaultValueStartIndex = pathComponentPart.index(after: defaultValueStartIndex)
                parameter.defaultValue = .forced(String(pathComponentPart[defaultValueStartIndex..<defaultValueEndIndex]))
            }

            parameter.name = String(pathComponentPart[nameStartIndex..<nameEndIndex])

            return parameter
        }

        return nil
    }
}
