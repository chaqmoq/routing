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
        let regex = try! NSRegularExpression(pattern: pattern)
        let pathComponents = path.components(separatedBy: "/").filter({ $0 != "" })
        if pathComponents.isEmpty { return false }

        for pathComponent in pathComponents {
            let range = NSRange(location: 0, length: pathComponent.utf8.count)
            let matches = regex.matches(in: pathComponent, range: range)

            if matches.isEmpty {
                return false
            } else {
                var matchesString = ""

                for match in matches {
                    let pathComponentPart = String(pathComponent[Range(match.range, in: pathComponent)!])

                    if pathComponentPart.hasPrefix(String(Parameter.nameEnclosingSymbols.0)),
                        var startIndex = pathComponentPart.range(of: String(Parameter.requirementEnclosingSymbols.0))?.lowerBound,
                        var endIndex = pathComponentPart.range(of: String(Parameter.requirementEnclosingSymbols.1))?.upperBound {
                        startIndex = pathComponentPart.index(after: startIndex)
                        endIndex = pathComponentPart.index(before: endIndex)
                        let pattern = String(pathComponentPart[startIndex..<endIndex])
                        let regex = try? NSRegularExpression(pattern: pattern)

                        if regex == nil {
                            return false
                        }
                    }

                    matchesString.append(pathComponentPart)
                }

                if matchesString != pathComponent {
                    return false
                }
            }
        }

        return true
    }
}
