extension Route {
    public struct Parameter {
        public static let nameEnclosingSymbols: (Character, Character) = ("{", "}")
        public static let requirementEnclosingSymbols: (Character, Character) = ("<", ">")
        public static let optionalSymbol: Character = "?"
        public static let requiredSymbol: Character = "!"

        public var name: String
        public var value: String?
        public var requirement: String?
        public var defaultValue: DefaultValue

        public init(name: String, defaultValue: DefaultValue = .none) {
            self.name = name
            self.defaultValue = defaultValue
        }
    }
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

        pattern += "\(defaultValue)\(Route.Parameter.nameEnclosingSymbols.1)"

        return pattern
    }
}