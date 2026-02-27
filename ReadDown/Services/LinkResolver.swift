import Foundation

enum LinkResolver {
    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd"]

    static func isMarkdownFile(_ url: URL) -> Bool {
        markdownExtensions.contains(url.pathExtension.lowercased())
    }

    static func resolve(href: String, relativeTo baseURL: URL?) -> URL? {
        if href.hasPrefix("http://") || href.hasPrefix("https://") {
            return URL(string: href)
        }

        guard let base = baseURL else { return nil }
        let resolved = base.deletingLastPathComponent().appendingPathComponent(href)
        return resolved.standardized
    }
}
