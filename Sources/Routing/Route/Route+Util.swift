import struct Foundation.NSRange
import class Foundation.NSRegularExpression

extension Route {
    /// Checks if a path is valid or not.
    /// 
    /// - Parameter path: A path to a resource.
    /// - Returns: If the path is valid, it returns `true` and a set of extracted parameters. Otherwise, it returns `false` and `nil`.
    public static func isValid(path: String) -> (Bool, Set<Parameter>?) {
        let separator = Route.defaultPath
        if path == separator { return (true, nil) }
        if !path.starts(with: separator) || path.contains(separator + separator) { return (false, nil) }
        guard let regex = try? NSRegularExpression(pattern: Route.pathPattern) else { return (false, nil) }
        let pathComponents = path.components(separatedBy: separator).filter({ $0 != "" })
        var parameters: Set<Parameter> = .init()

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
                            let pattern = String(pathComponentPart[startIndex..<endIndex])
                            if (try? NSRegularExpression(pattern: pattern)) == nil { return (false, nil) }
                        }
                    }

                    if let parameter = Route.createParameter(from: pathComponentPart) {
                        parameters.insert(parameter)
                    }

                    matchesString.append(pathComponentPart)
                }
            }

            if matchesString != pathComponent { return (false, nil) }
        }

        return (true, parameters.isEmpty ? nil : parameters)
    }

    /// Normalizes a path.
    ///
    /// - Parameter path: A path to a resource.
    /// - Returns: A normalized path.
    public static func normalize(path: String) -> String {
        let separator = Route.defaultPath
        let doubleSeparator = separator + separator

        return !path.isEmpty &&
            path != separator &&
            path.last == separator.last &&
            !path.hasSuffix(doubleSeparator)
            ? String(path.dropLast())
            : path
    }

    /// Generates a regular expression pattern for a path and parameters.
    ///
    /// - Parameters:
    ///   - path: A path to a resource.
    ///   - parameters: A set of parameters.
    /// - Returns: A regular expression pattern.
    public static func generatePattern(for path: String, with parameters: Set<Parameter>? = nil) -> String {
        var pattern = path

        if let parameters = parameters {
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
        }

        return pattern
    }

    /// Creates an instance of `Parameter` from a parameter pattern `{name<requirement>?defaultValue}`.
    ///
    /// - Parameter part: A part of a path component.
    /// - Returns: An instance of `Parameter` or `nil`.
    public static func createParameter(from part: String) -> Parameter? {
        if var nameStartIndex = part.firstIndex(of: Parameter.nameEnclosingSymbols.0),
            var nameEndIndex = part.firstIndex(of: Parameter.nameEnclosingSymbols.1) {
            nameStartIndex = part.index(after: nameStartIndex)
            var requirement = ""
            var defaultValue: Parameter.DefaultValue?

            if var requirementStartIndex = part.firstIndex(of: Parameter.requirementEnclosingSymbols.0),
                let requirementEndIndex = part.firstIndex(of: Parameter.requirementEnclosingSymbols.1) {
                if var defaultValueStartIndex = part.firstIndex(of: Parameter.optionalSymbol) {
                    let defaultValueEndIndex = nameEndIndex
                    defaultValueStartIndex = part.index(after: defaultValueStartIndex)
                    defaultValue = .optional(String(part[defaultValueStartIndex..<defaultValueEndIndex]))
                } else if var defaultValueStartIndex = part.firstIndex(of: Parameter.forcedSymbol) {
                    let defaultValueEndIndex = nameEndIndex
                    defaultValueStartIndex = part.index(after: defaultValueStartIndex)
                    defaultValue = .forced(String(part[defaultValueStartIndex..<defaultValueEndIndex]))
                }

                nameEndIndex = requirementStartIndex
                requirementStartIndex = part.index(after: requirementStartIndex)
                requirement = String(part[requirementStartIndex..<requirementEndIndex])
            } else if var defaultValueStartIndex = part.firstIndex(of: Parameter.optionalSymbol) {
                let defaultValueEndIndex = nameEndIndex
                nameEndIndex = defaultValueStartIndex
                defaultValueStartIndex = part.index(after: defaultValueStartIndex)
                defaultValue = .optional(String(part[defaultValueStartIndex..<defaultValueEndIndex]))
            } else if var defaultValueStartIndex = part.firstIndex(of: Parameter.forcedSymbol) {
                let defaultValueEndIndex = nameEndIndex
                nameEndIndex = defaultValueStartIndex
                defaultValueStartIndex = part.index(after: defaultValueStartIndex)
                defaultValue = .forced(String(part[defaultValueStartIndex..<defaultValueEndIndex]))
            }

            return Parameter(
                name: String(part[nameStartIndex..<nameEndIndex]),
                requirement: requirement,
                defaultValue: defaultValue
            )
        }

        return nil
    }
}
