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
        public var name: String
        public var value: String?
        public var requirement: String?
        public var defaultValue: DefaultValue

        public enum DefaultValue {
            case none
            case optional(_ value: String)
            case required(_ value: String)
        }

        public var pattern: String {
            var pattern = "{\(name)"

            if let requirement = requirement {
                pattern += "<\(requirement)>"
            }

            switch defaultValue {
            case .optional(let value):
                pattern += "?\(value)"
            case .required(let value):
                pattern += "!\(value)"
            default:
                break
            }

            pattern += "}"

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

                    if subComponent.hasPrefix("{"),
                        var startIndex = subComponent.range(of: "<")?.lowerBound,
                        var endIndex = subComponent.range(of: ">")?.upperBound {
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
