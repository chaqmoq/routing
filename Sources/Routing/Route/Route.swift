import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request
import struct HTTP.Response

public struct Route {
    public typealias RequestHandler = (Request) -> Any

    static let textPattern = "[a-zA-Z0-9_~.-]+"
    static let parameterNamePattern = "\\w+"
    static let parameterPattern = """
    (\\{\(parameterNamePattern)(<[^\\/{}<>]+>)?(\\?([a-zA-Z0-9_~.-]+)?|![a-zA-Z0-9_~.-]+)?\\})+
    """
    static let pathPattern = "\(textPattern)|\(parameterPattern)"
    static let pathComponentSeparator: Character = "/"

    public var method: Request.Method
    public private(set) var path: String
    public private(set) var pattern: String
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
        self.path = path
        pattern = path
        self.name = name
        self.requestHandler = requestHandler

        if isValid(path: path) {
            let separator = Route.pathComponentSeparator
            self.path = path != String(separator) && path.last == separator ? String(path.dropLast()) : path
            pattern = mapPathToPattern()
            guard pattern == "" || (try? NSRegularExpression(pattern: pattern)) != nil else { return nil }
        } else {
            return nil
        }
    }
}

extension Route: Hashable {
    public static func ==(lhs: Route, rhs: Route) -> Bool {
        if let name = lhs.name, !name.isEmpty {
            return name == rhs.name
        }

        return lhs.method == rhs.method && lhs.pattern == rhs.pattern
    }

    public func hash(into hasher: inout Hasher) {
        if let name = name, !name.isEmpty {
            hasher.combine(name)
        } else {
            hasher.combine(method)
            hasher.combine(pattern)
        }
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
    mutating func isValid(path: String) -> Bool {
        let separator = String(Route.pathComponentSeparator)
        if path == "" || path == separator { return true }
        if !path.starts(with: separator) || path.contains(separator + separator) { return false }
        guard let regex = try? NSRegularExpression(pattern: Route.pathPattern) else { return false }
        let pathComponents = path.components(separatedBy: separator).filter({ $0 != "" })

        for pathComponent in pathComponents {
            let range = NSRange(location: 0, length: pathComponent.utf8.count)
            let matches = regex.matches(in: pathComponent, range: range)

            if matches.isEmpty {
                return false
            } else {
                var matchesString = ""

                for match in matches {
                    if let range = Range(match.range, in: pathComponent) {
                        let pathComponentPart = String(pathComponent[range])

                        if pathComponentPart.hasPrefix(String(Parameter.nameEnclosingSymbols.0)) {
                            let requirementEnclosingSymbols = Parameter.requirementEnclosingSymbols
                            let startRange = pathComponentPart.range(of: String(requirementEnclosingSymbols.0))
                            let endRange = pathComponentPart.range(of: String(requirementEnclosingSymbols.1))

                            if let startIndex = startRange?.upperBound,
                                let endIndex = endRange?.lowerBound {
                                let pattern = String(pathComponentPart[startIndex..<endIndex])
                                if (try? NSRegularExpression(pattern: pattern)) == nil { return false }
                            }
                        }

                        if let parameter = extractParameter(from: pathComponentPart) {
                            if let parameters = parameters {
                                if parameters.contains(parameter) {
                                    return false
                                } else {
                                    self.parameters?.insert(parameter)
                                }
                            } else {
                                parameters = [parameter]
                            }
                        }

                        matchesString.append(pathComponentPart)
                    }
                }

                if matchesString != pathComponent { return false }
            }
        }

        return true
    }

    func mapPathToPattern() -> String {
        var pattern = path

        if let parameters = parameters {
            let separator = String(Route.pathComponentSeparator)

            for parameter in parameters {
                if parameter.defaultValue != nil, let range = pattern.range(of: "\(separator)\(parameter)") {
                    if range.upperBound == pattern.endIndex || String(pattern[range.upperBound]) == separator {
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
                }

                pattern = pattern.replacingOccurrences(of: "\(parameter)", with: parameter.pattern)
            }
        }

        return pattern
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
                    parameter.defaultValue = .optional(
                        String(pathComponentPart[defaultValueStartIndex..<defaultValueEndIndex])
                    )
                } else if var defaultValueStartIndex = pathComponentPart.firstIndex(of: Parameter.forcedSymbol) {
                    let defaultValueEndIndex = nameEndIndex
                    defaultValueStartIndex = pathComponentPart.index(after: defaultValueStartIndex)
                    parameter.defaultValue = .forced(
                        String(pathComponentPart[defaultValueStartIndex..<defaultValueEndIndex])
                    )
                }

                nameEndIndex = requirementStartIndex
                requirementStartIndex = pathComponentPart.index(after: requirementStartIndex)
                parameter.requirement = String(pathComponentPart[requirementStartIndex..<requirementEndIndex])
            } else if var defaultValueStartIndex = pathComponentPart.firstIndex(of: Parameter.optionalSymbol) {
                let defaultValueEndIndex = nameEndIndex
                nameEndIndex = defaultValueStartIndex
                defaultValueStartIndex = pathComponentPart.index(after: defaultValueStartIndex)
                parameter.defaultValue = .optional(
                    String(pathComponentPart[defaultValueStartIndex..<defaultValueEndIndex])
                )
            } else if var defaultValueStartIndex = pathComponentPart.firstIndex(of: Parameter.forcedSymbol) {
                let defaultValueEndIndex = nameEndIndex
                nameEndIndex = defaultValueStartIndex
                defaultValueStartIndex = pathComponentPart.index(after: defaultValueStartIndex)
                parameter.defaultValue = .forced(
                    String(pathComponentPart[defaultValueStartIndex..<defaultValueEndIndex])
                )
            }

            parameter.name = String(pathComponentPart[nameStartIndex..<nameEndIndex])

            return parameter
        }

        return nil
    }
}
