extension Route {
    public struct Parameter {
        public var name: String
        public var value: String
        public var requirement: String?
        public var defaultValue: DefaultValue?

        public init(
            name: String,
            value: String = "",
            requirement: String? = nil,
            defaultValue: DefaultValue? = nil
        ) {
            self.name = name
            self.value = value
            self.requirement = requirement
            self.defaultValue = defaultValue
        }
    }
}

extension Route.Parameter {
    public var pattern: String {
        if let requirement = requirement {
            if let defaultValue = defaultValue {
                switch defaultValue {
                case .optional(let value),
                     .forced(let value):
                    if value.isEmpty { return "(\(requirement))?" }
                    return "(\(requirement)|\(value))?"
                }
            }

            return "(\(requirement))"
        } else if let defaultValue = defaultValue {
            switch defaultValue {
            case .optional(let value),
                 .forced(let value):
                if value.isEmpty { return "(.+)?" }
                return "(.+|\(value))?"
            }
        }

        return "(.+)"
    }
}

extension Route.Parameter {
    static let nameEnclosingSymbols: (Character, Character) = ("{", "}")
    static let requirementEnclosingSymbols: (Character, Character) = ("<", ">")
    static let optionalSymbol: Character = "?"
    static let forcedSymbol: Character = "!"
}

extension Route.Parameter: Hashable {
    public static func ==(lhs: Route.Parameter, rhs: Route.Parameter) -> Bool { lhs.name == rhs.name }
    public func hash(into hasher: inout Hasher) { hasher.combine(name) }
}

extension Route.Parameter: CustomStringConvertible {
    public var description: String {
        var pattern = "\(Route.Parameter.nameEnclosingSymbols.0)\(name)"

        if let requirement = requirement {
            let requirementEnclosingSymbols = Route.Parameter.requirementEnclosingSymbols
            pattern += "\(requirementEnclosingSymbols.0)\(requirement)\(requirementEnclosingSymbols.1)"
        }

        if let defaultValue = defaultValue { pattern += "\(defaultValue)" }
        pattern += "\(Route.Parameter.nameEnclosingSymbols.1)"

        return pattern
    }
}
