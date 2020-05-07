import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request
import struct HTTP.Response

public struct Route {
    public typealias RequestHandler = (Request) -> Any

    public var method: Request.Method
    public let path: String
    public var name: String?
    public var parameters: Set<Parameter>?
    public var requestHandler: RequestHandler

    public init?(
        method: Request.Method,
        path: String = "/",
        name: String? = nil,
        requestHandler: @escaping RequestHandler
    ) {
        self.method = method
        self.path = path
        self.name = name
        self.requestHandler = requestHandler

        if !isValid(path: path) {
            return nil
        }
    }
}

extension Route {
    public struct Parameter: Hashable {
        public static let nameBoundarySymbols: (Character, Character) = ("{", "}")
        public static let requirementBoundarySymbols: (Character, Character) = ("<", ">")
        public static let optionalSymbol: Character = "?"
        public static let requiredSymbol: Character = "!"

        public var name: String
        public var value: String?
        public var requirement: String?
        public var defaultValue: DefaultValue

        public enum DefaultValue {
            case none
            case optional(_ value: String? = nil)
            case required(_ value: String)
        }

        public var pattern: String {
            var pattern = "\(Parameter.nameBoundarySymbols.0)\(name)"

            if let requirement = requirement {
                pattern += "\(Parameter.requirementBoundarySymbols.0)\(requirement)\(Parameter.requirementBoundarySymbols.1)"
            }

            switch defaultValue {
            case .optional(let value):
                if let value = value {
                    pattern += "\(Parameter.optionalSymbol)\(value)"
                } else {
                    pattern += String(Parameter.optionalSymbol)
                }
            case .required(let value):
                pattern += "\(Parameter.requiredSymbol)\(value)"
            default:
                break
            }

            pattern += String(Parameter.nameBoundarySymbols.1)

            return pattern
        }

        public init(name: String, defaultValue: DefaultValue = .none) {
            self.name = name
            self.defaultValue = defaultValue
        }

        public static func ==(lhs: Parameter, rhs: Parameter) -> Bool {
            lhs.name == rhs.name
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }
}

extension Route: Hashable {
    public static func == (lhs: Route, rhs: Route) -> Bool {
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

        if let name = name {
            description.append("\nname=\(name)")
        }

        return description
    }
}

extension Route {
    public func isValid(path: String) -> Bool {
        if path == "/" { return true }
        if path.contains("//") { return false }
        let pattern = "[a-zA-Z0-9_~.-]+|(\\{\\w+(<[^\\/<>]+>)?(\\?([a-zA-Z0-9_~.-]+)?|![a-zA-Z0-9_~.-]+)?\\})+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let components = path.components(separatedBy: "/").filter({ $0 != "" })
        if components.isEmpty { return false }

        for component in components {
            let range = NSRange(location: 0, length: component.utf8.count)
            let matches = regex.matches(in: component, range: range)

            if matches.isEmpty {
                return false
            } else {
                var matchesString = ""

                for match in matches {
                    let subComponent = String(component[Range(match.range, in: component)!])

                    if subComponent.hasPrefix(String(Parameter.nameBoundarySymbols.0)),
                        var startIndex = subComponent.range(of: String(Parameter.requirementBoundarySymbols.0))?.lowerBound,
                        var endIndex = subComponent.range(of: String(Parameter.requirementBoundarySymbols.1))?.upperBound {
                        startIndex = subComponent.index(after: startIndex)
                        endIndex = subComponent.index(before: endIndex)
                        let pattern = String(subComponent[startIndex..<endIndex])
                        let regex = try? NSRegularExpression(pattern: pattern)

                        if regex == nil {
                            return false
                        }
                    }

                    matchesString.append(subComponent)
                }

                if matchesString != component {
                    return false
                }
            }
        }

        return true
    }
}
