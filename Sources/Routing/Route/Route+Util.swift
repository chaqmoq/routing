import struct Foundation.NSRange
import class Foundation.NSRegularExpression

extension Route {
    public static func isValid(path: String) -> (Bool, Set<Parameter>?) {
        let separator = String(Route.pathComponentSeparator)
        if path == separator { return (true, nil) }
        if !path.starts(with: separator) || path.contains(separator + separator) { return (false, nil) }
        guard let regex = try? NSRegularExpression(pattern: Route.pathPattern) else { return (false, nil) }
        let pathComponents = path.components(separatedBy: separator).filter({ $0 != "" })
        var parameters: Set<Parameter> = .init()

        for pathComponent in pathComponents {
            let range = NSRange(location: 0, length: pathComponent.utf8.count)
            let matches = regex.matches(in: pathComponent, range: range)

            if matches.isEmpty {
                return (false, nil)
            } else {
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

                        if let parameter = Route.extractParameter(from: pathComponentPart) {
                            if parameters.contains(parameter) {
                                return (false, nil)
                            } else {
                                parameters.insert(parameter)
                            }
                        }

                        matchesString.append(pathComponentPart)
                    }
                }

                if matchesString != pathComponent { return (false, nil) }
            }
        }

        return (true, parameters.isEmpty ? nil : parameters)
    }

    public static func normalize(path: String) -> String {
        let separator = String(Route.pathComponentSeparator)
        let doubleSeparator = separator + separator

        return !path.isEmpty &&
            path != separator &&
            path.last == separator.last &&
            !path.hasSuffix(doubleSeparator)
            ? String(path.dropLast())
            : path
    }

    public static func generatePattern(from path: String, parameters: Set<Parameter>? = nil) -> String {
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

    public static func extractParameter(from pathComponentPart: String) -> Parameter? {
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
