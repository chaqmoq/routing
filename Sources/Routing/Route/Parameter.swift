import Foundation

extension Route {
    /// An extracted parameter from the path of `Route`.
    public struct Parameter {
        static let nameEnclosingSymbols: (Character, Character) = ("{", "}")
        static let requirementEnclosingSymbols: (Character, Character) = ("<", ">")
        static let optionalSymbol: Character = "?"
        static let forcedSymbol: Character = "!"

        /// A unique name.
        public let name: String

        /// A validated value by the requirement.
        public var value: String

        /// A regular expression for the value.
        public let requirement: String

        /// A default value if the value is missing.
        public let defaultValue: DefaultValue?

        /// Initializes a new instance or `nil`.
        ///
        /// - Warning: It may return `nil` if the name is missing, the value doesn't conform to the requirement, the requirement is invalid or
        /// the default value is invalid.
        /// - Parameters:
        ///   - name: A unique name.
        ///   - value: A validated value by the requirement.
        ///   - requirement: A regular expression for the value.
        ///   - defaultValue: A default value if the value is missing.
        public init?(name: String, value: String = "", requirement: String = "", defaultValue: DefaultValue? = nil) {
            if name.isEmpty || defaultValue == .forced("") { return nil }
            self.name = name
            self.value = value
            self.requirement = requirement
            self.defaultValue = defaultValue

            if !self.requirement.isEmpty {
                guard let regex = try? NSRegularExpression(pattern: self.requirement) else { return nil }

                if !self.value.isEmpty {
                    let valueRange = NSRange(location: 0, length: self.value.utf8.count)
                    guard regex.firstMatch(in: self.value, range: valueRange) != nil else { return nil }
                }
            }
        }
    }
}

extension Route.Parameter {
    /// A generated pattern for the parameter.
    public var pattern: String {
        if !requirement.isEmpty {
            if let defaultValue = defaultValue {
                switch defaultValue {
                case let .optional(value),
                     let .forced(value):
                    if value.isEmpty { return "(\(requirement))?" }
                    return "(\(requirement)|\(value))?"
                }
            }

            return "(\(requirement))"
        } else if let defaultValue = defaultValue {
            switch defaultValue {
            case let .optional(value),
                 let .forced(value):
                if value.isEmpty { return "(.+)?" }
                return "(.+|\(value))?"
            }
        }

        return "(.+)"
    }
}

extension Route.Parameter: Hashable {
    /// See `Equatable`.
    public static func == (lhs: Route.Parameter, rhs: Route.Parameter) -> Bool { lhs.name == rhs.name }

    /// See `Hashable`.
    public func hash(into hasher: inout Hasher) { hasher.combine(name) }
}

extension Route.Parameter: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    public var description: String {
        var pattern = "\(Route.Parameter.nameEnclosingSymbols.0)\(name)"

        if !requirement.isEmpty {
            let requirementEnclosingSymbols = Route.Parameter.requirementEnclosingSymbols
            pattern += "\(requirementEnclosingSymbols.0)\(requirement)\(requirementEnclosingSymbols.1)"
        }

        if let defaultValue = defaultValue { pattern += "\(defaultValue)" }
        pattern += "\(Route.Parameter.nameEnclosingSymbols.1)"

        return pattern
    }
}
