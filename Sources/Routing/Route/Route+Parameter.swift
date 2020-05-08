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

        public var pattern: String {
            var pattern = "\(Parameter.nameEnclosingSymbols.0)\(name)"

            if let requirement = requirement {
                pattern += "\(Parameter.requirementEnclosingSymbols.0)\(requirement)\(Parameter.requirementEnclosingSymbols.1)"
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

            pattern += String(Parameter.nameEnclosingSymbols.1)

            return pattern
        }

        public init(name: String, defaultValue: DefaultValue = .none) {
            self.name = name
            self.defaultValue = defaultValue
        }
    }
}

extension Route.Parameter: Hashable {
    public static func ==(lhs: Route.Parameter, rhs: Route.Parameter) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension Route.Parameter {
    public enum DefaultValue: Equatable {
        case none
        case optional(_ value: String? = nil)
        case required(_ value: String)
    }
}
