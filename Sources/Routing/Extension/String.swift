extension String {
    /// Splits the string by `"/"` and returns the non-empty components.
    ///
    /// `"/api/v1/posts".paths` → `["api", "v1", "posts"]`
    var paths: [String] {
        split(separator: "/").map { String($0) }
    }

    /// Joins two URL path strings, normalising duplicate and trailing slashes.
    ///
    /// ```swift
    /// "/api".appending(path: "/v1")  // → "/api/v1"
    /// "/api/".appending(path: "/v1") // → "/api/v1"   (trailing slash stripped)
    /// "/api".appending(path: "/")    // → "/api"       (appending root is a no-op)
    /// "/".appending(path: "/v1")     // → "/v1"
    /// ```
    func appending(path: String) -> String {
        var prefix = self
        var suffix = path

        if prefix != "/" && prefix.last == "/" {
            prefix = String(prefix.dropLast())
        }

        // Appending the root path "/" to any prefix is a no-op.
        // Without this guard, "/foo" + "/" would produce "/foo/" (trailing slash).
        if suffix == "/" { return prefix }

        if suffix.last == "/" {
            suffix = String(suffix.dropLast())
        }

        prefix += suffix

        return prefix.starts(with: "//") ? String(prefix.dropFirst()) : prefix
    }
}
