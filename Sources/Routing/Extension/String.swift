extension String {
    var paths: [String] {
        split(separator: "/").map { String($0) }
    }

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
