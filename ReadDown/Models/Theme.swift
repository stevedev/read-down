import Foundation

enum Theme: String, CaseIterable, Identifiable {
    case githubLight = "github-light"
    case githubDark = "github-dark"
    case dracula
    case oneDark = "one-dark"
    case nord
    case solarizedLight = "solarized-light"
    case solarizedDark = "solarized-dark"
    case monokai

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .githubLight: "GitHub Light"
        case .githubDark: "GitHub Dark"
        case .dracula: "Dracula"
        case .oneDark: "One Dark"
        case .nord: "Nord"
        case .solarizedLight: "Solarized Light"
        case .solarizedDark: "Solarized Dark"
        case .monokai: "Monokai"
        }
    }

    var cssFileName: String { rawValue }

    var isDark: Bool {
        switch self {
        case .githubLight, .solarizedLight: false
        default: true
        }
    }
}
