import Foundation
import HTTP

/// A type that can be initialised from a route parameter's raw string value.
///
/// Conform your own types to use them with ``Route``'s typed parameter subscript:
/// ```swift
/// struct UserID: RouteParameterConvertible {
///     let rawValue: Int
///     static func convert(from string: String) -> UserID? {
///         Int(string).map(UserID.init(rawValue:))
///     }
/// }
/// let id: UserID? = route[parameter: "id"]
/// ```
public protocol RouteParameterConvertible {
    static func convert(from string: String) -> Self?
}

extension String: RouteParameterConvertible { public static func convert(from s: String) -> String? { s } }
extension Int: RouteParameterConvertible { public static func convert(from s: String) -> Int? { Int(s) } }
extension Int8: RouteParameterConvertible { public static func convert(from s: String) -> Int8? { Int8(s) } }
extension Int16: RouteParameterConvertible { public static func convert(from s: String) -> Int16? { Int16(s) } }
extension Int32: RouteParameterConvertible { public static func convert(from s: String) -> Int32? { Int32(s) } }
extension Int64: RouteParameterConvertible { public static func convert(from s: String) -> Int64? { Int64(s) } }
extension UInt: RouteParameterConvertible { public static func convert(from s: String) -> UInt? { UInt(s) } }
extension UInt8: RouteParameterConvertible { public static func convert(from s: String) -> UInt8? { UInt8(s) } }
extension UInt16: RouteParameterConvertible { public static func convert(from s: String) -> UInt16? { UInt16(s) } }
extension UInt32: RouteParameterConvertible { public static func convert(from s: String) -> UInt32? { UInt32(s) } }
extension UInt64: RouteParameterConvertible { public static func convert(from s: String) -> UInt64? { UInt64(s) } }
extension Double: RouteParameterConvertible { public static func convert(from s: String) -> Double? { Double(s) } }
extension Float: RouteParameterConvertible { public static func convert(from s: String) -> Float? { Float(s) } }
extension Bool: RouteParameterConvertible { public static func convert(from s: String) -> Bool? { Bool(s) } }
extension UUID: RouteParameterConvertible { public static func convert(from s: String) -> UUID? { UUID(uuidString: s) } }
extension URL: RouteParameterConvertible { public static func convert(from s: String) -> URL? { URL(string: s) } }
extension Date: RouteParameterConvertible {
    public static func convert(from string: String) -> Date? {
        Route.dateFormatter.date(from: string)
    }
}
